package fuzz

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"gopkg.in/yaml.v3"
)

// errRejected means the input is not a values overlay Helm can render.
// Coverage-guided fuzzing is expected to produce many such inputs.
var errRejected = errors.New("rejected input")

// errPanicked means the Helm renderer aborted with a panic. That is a bug.
var errPanicked = errors.New("helm panicked")

// FuzzRender feeds arbitrary bytes to `helm template` as a values overlay
// for this repository's chart. Inputs Helm rejects are discarded. Inputs
// Helm accepts must render as YAML documents, and the renderer must not panic.
func FuzzRender(f *testing.F) {
	f.Add([]byte("replicaCount: 1\n"))
	f.Add([]byte("{}\n"))
	f.Add([]byte("service:\n  type: ClusterIP\n  port: 6901\n"))
	f.Add([]byte("persistence:\n  enabled: false\n"))
	f.Add([]byte("image:\n  repository: kasmweb/signal\n  tag: \"1.18.0\"\n  pullPolicy: IfNotPresent\n"))
	f.Add([]byte("nameOverride: fuzz\nfullnameOverride: fuzz\n"))
	f.Add([]byte("not yaml: [\n"))
	f.Fuzz(func(t *testing.T, data []byte) {
		out, err := renderChart(data)
		if errors.Is(err, errRejected) {
			return
		}
		if err != nil {
			t.Fatal(err)
		}
		if err := validateManifests(out); err != nil {
			t.Fatalf("rendered manifests are not valid YAML: %v\n%s", err, out)
		}
	})
}

func TestRenderDefaults(t *testing.T) {
	out, err := renderChart([]byte("replicaCount: 1\n"))
	if err != nil {
		t.Fatal(err)
	}
	if err := validateManifests(out); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "kind: StatefulSet") && !strings.Contains(out, "kind: Service") {
		t.Fatalf("expected a Service or StatefulSet in the render:\n%s", out)
	}
}

func renderChart(data []byte) (string, error) {
	if len(data) > 64*1024 {
		return "", errRejected
	}
	chart, err := locateChart()
	if err != nil {
		return "", err
	}
	helm, err := locateHelm()
	if err != nil {
		return "", err
	}

	dir, err := os.MkdirTemp("", "ghostwire-fuzz")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(dir)

	values := filepath.Join(dir, "values.yaml")
	if err := os.WriteFile(values, data, 0o600); err != nil {
		return "", err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, helm, "template", "fuzz", chart, "--namespace", "default", "-f", values)
	cmd.Env = append(os.Environ(),
		"HELM_CACHE_HOME="+filepath.Join(dir, "cache"),
		"HELM_CONFIG_HOME="+filepath.Join(dir, "config"),
		"HELM_DATA_HOME="+filepath.Join(dir, "data"),
	)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	runErr := cmd.Run()
	combined := stdout.String() + "\n" + stderr.String()
	if strings.Contains(combined, "panic:") || strings.Contains(combined, "runtime error:") {
		return combined, errPanicked
	}
	if runErr != nil {
		return "", errRejected
	}
	return stdout.String(), nil
}

func locateChart() (string, error) {
	if p := os.Getenv("GHOSTWIRE_CHART"); p != "" {
		if _, err := os.Stat(filepath.Join(p, "Chart.yaml")); err == nil {
			return p, nil
		}
	}
	if exe, err := os.Executable(); err == nil {
		cand := filepath.Join(filepath.Dir(exe), "chart")
		if _, err := os.Stat(filepath.Join(cand, "Chart.yaml")); err == nil {
			return cand, nil
		}
	}
	_, file, _, ok := runtime.Caller(0)
	if ok {
		cand := filepath.Clean(filepath.Join(filepath.Dir(file), "..", "chart"))
		if _, err := os.Stat(filepath.Join(cand, "Chart.yaml")); err == nil {
			return cand, nil
		}
	}
	return "", errors.New("chart directory not found")
}

func locateHelm() (string, error) {
	if p, err := exec.LookPath("helm"); err == nil {
		return p, nil
	}
	if exe, err := os.Executable(); err == nil {
		cand := filepath.Join(filepath.Dir(exe), "helm")
		if _, err := os.Stat(cand); err == nil {
			return cand, nil
		}
	}
	return "", errors.New("helm not found on PATH")
}

func validateManifests(out string) error {
	parts := strings.Split(out, "\n---")
	for _, part := range parts {
		chunk := strings.TrimSpace(part)
		if chunk == "" || chunk == "---" {
			continue
		}
		if strings.Contains(chunk, "NOTES.txt") && !strings.Contains(chunk, "apiVersion:") {
			continue
		}
		dec := yaml.NewDecoder(strings.NewReader(chunk))
		for {
			var doc any
			err := dec.Decode(&doc)
			if errors.Is(err, io.EOF) {
				break
			}
			if err != nil {
				if strings.Contains(chunk, "NOTES.txt") {
					break
				}
				return err
			}
		}
	}
	return nil
}
