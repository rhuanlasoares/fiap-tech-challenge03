package main

import (
	"crypto/sha1"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path"
	"sync"
	"time"
)

const (
	CACHE_TTL = 30 * time.Second
)

func (a *App) getDecision(userID, flagName string) (bool, error) {
	info, err := a.getCombinedFlagInfo(flagName)
	if err != nil {
		return false, err
	}
	return a.runEvaluationLogic(info, userID), nil
}

func (a *App) getCombinedFlagInfo(flagName string) (*CombinedFlagInfo, error) {
	cacheKey := fmt.Sprintf("flag_info:%s", flagName)

	val, err := a.RedisClient.Get(ctx, cacheKey).Result()
	if err == nil {
		var info CombinedFlagInfo
		if err := json.Unmarshal([]byte(val), &info); err == nil {
			log.Printf("Cache HIT para flag '%s'", flagName)
			return &info, nil
		}
		log.Printf("Erro ao desserializar cache para flag '%s': %v", flagName, err)
	}

	log.Printf("Cache MISS para flag '%s'", flagName)
	info, err := a.fetchFromServices(flagName)
	if err != nil {
		return nil, err
	}

	jsonData, err := json.Marshal(info)
	if err == nil {
		if errSet := a.RedisClient.Set(ctx, cacheKey, jsonData, CACHE_TTL).Err(); errSet != nil {
			log.Printf("Aviso: falha ao salvar cache no Redis para a flag '%s': %v", flagName, errSet)
		}
	}

	return info, nil
}

func (a *App) fetchFromServices(flagName string) (*CombinedFlagInfo, error) {
	var wg sync.WaitGroup
	wg.Add(2)

	var flagInfo *Flag
	var ruleInfo *TargetingRule
	var flagErr, ruleErr error

	go func() {
		defer wg.Done()
		flagInfo, flagErr = a.fetchFlag(flagName)
	}()

	go func() {
		defer wg.Done()
		ruleInfo, ruleErr = a.fetchRule(flagName)
	}()

	wg.Wait()

	if flagErr != nil {
		return nil, flagErr
	}
	if ruleErr != nil {
		log.Printf("Aviso: Nenhuma regra de segmentação encontrada para '%s'. Usando padrão.", flagName)
	}

	return &CombinedFlagInfo{
		Flag: flagInfo,
		Rule: ruleInfo,
	}, nil
}

func (a *App) fetchFlag(flagName string) (*Flag, error) {
	// Reconstrução segura para mitigar G704
	u, err := url.Parse(a.FlagServiceURL)
	if err != nil {
		return nil, fmt.Errorf("URL base inválida: %w", err)
	}
	u.Path = path.Join(u.Path, "flags", flagName)

	apiKey := os.Getenv("SERVICE_API_KEY")
	// #nosec G704 - URL construída via url.URL isolando o host
	req, err := http.NewRequest("GET", u.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("erro ao criar requisição para flag-service: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar flag-service: %w", err)
	}

	defer func() {
		if errClose := resp.Body.Close(); errClose != nil {
			log.Printf("Aviso: erro ao fechar corpo da resposta do flag-service: %v", errClose)
		}
	}()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("flag-service retornou status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler corpo da resposta do flag-service: %w", err)
	}

	var flag Flag
	if err := json.Unmarshal(body, &flag); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do flag-service: %w", err)
	}
	return &flag, nil
}

func (a *App) fetchRule(flagName string) (*TargetingRule, error) {
	// Reconstrução segura para mitigar G704
	u, err := url.Parse(a.TargetingServiceURL)
	if err != nil {
		return nil, fmt.Errorf("URL base inválida: %w", err)
	}
	u.Path = path.Join(u.Path, "rules", flagName)

	apiKey := os.Getenv("SERVICE_API_KEY")

	// #nosec G704 - URL construída via url.URL isolando o host
	req, err := http.NewRequest("GET", u.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("erro ao criar requisição para targeting-service: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("erro ao chamar targeting-service: %w", err)
	}

	defer func() {
		if errClose := resp.Body.Close(); errClose != nil {
			log.Printf("Aviso: erro ao fechar corpo da resposta do targeting-service: %v", errClose)
		}
	}()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("targeting-service retornou status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler corpo da resposta do targeting-service: %w", err)
	}

	var rule TargetingRule
	if err := json.Unmarshal(body, &rule); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do targeting-service: %w", err)
	}
	return &rule, nil
}

func (a *App) runEvaluationLogic(info *CombinedFlagInfo, userID string) bool {
	if info.Flag == nil || !info.Flag.IsEnabled {
		return false
	}

	if info.Rule == nil || !info.Rule.IsEnabled {
		return true
	}

	rule := info.Rule.Rules
	if rule.Type == "PERCENTAGE" {
		percentage, ok := rule.Value.(float64)
		if !ok {
			log.Printf("Erro: valor da regra de porcentagem não é um número para a flag '%s'", info.Flag.Name)
			return false
		}

		userBucket := getDeterministicBucket(userID + info.Flag.Name)

		if float64(userBucket) < percentage {
			return true
		}
	}

	return false
}

func getDeterministicBucket(input string) int {
	hasher := sha1.New()
	hasher.Write([]byte(input))
	hash := hasher.Sum(nil)
	val := binary.BigEndian.Uint32(hash[:4])
	return int(val % 100)
}
