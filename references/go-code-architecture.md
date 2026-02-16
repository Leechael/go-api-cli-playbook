# Go Code Architecture Reference

Annotated code examples for the canonical Go API CLI structure.
All examples use `your-cli` / `myservice` as placeholders — replace with actual names from `release-naming.env`.

---

## 1. Package Layout

```
your-cli/
├── cmd/
│   └── your-cli/
│       └── main.go          # Entry point — nothing else here
├── internal/
│   ├── cmd/
│   │   ├── root.go          # NewRootCmd factory, global flags, exit codes
│   │   ├── status.go        # Simple command example
│   │   └── reader.go        # Resource group with subcommands
│   ├── client/
│   │   └── client.go        # HTTP client + params structs
│   ├── model/
│   │   ├── reader.go        # Response/request/update structs
│   │   └── common.go        # Shared types (pagination, errors)
│   └── output/
│       └── output.go        # Formatter (JSON/plain/jq)
├── tests/
│   └── bdd/
│       ├── features/
│       │   └── status.feature
│       └── steps/
│           └── status_test.go
├── release-naming.env
├── Makefile
├── go.mod
└── go.sum
```

---

## 2. Entry Point — `cmd/your-cli/main.go`

```go
// Package main is the entry point. It only calls the root command factory
// and exits with a mapped exit code. No logic lives here.
package main

import (
	"os"

	"github.com/owner/your-cli/internal/cmd"
)

func main() {
	rootCmd := cmd.NewRootCmd()
	err := rootCmd.Execute()
	os.Exit(cmd.ExitCode(err))
}
```

**Rules:**
- The `main()` function must be trivial — no flag parsing, no init, no globals.
- `cmd.ExitCode(err)` maps errors to stable exit codes.

---

## 3. Root Command — `internal/cmd/root.go`

```go
package cmd

import (
	"errors"
	"fmt"
	"os"

	"github.com/owner/your-cli/internal/client"
	"github.com/owner/your-cli/internal/output"
	"github.com/spf13/cobra"
)

// Exit code constants — must be stable for scripting.
const (
	ExitOK        = 0
	ExitError     = 1
	ExitAuth      = 2
	ExitNotFound  = 3
)

// NewRootCmd creates the root command. This is the ONLY public factory
// in this package. All subcommands are registered here.
func NewRootCmd() *cobra.Command {
	var (
		token   string
		jsonOut bool
		plain   bool
		jqExpr  string
	)

	cmd := &cobra.Command{
		Use:   "your-cli",
		Short: "CLI for MyService API",

		// Both must be true — we handle errors ourselves via ExitCode().
		SilenceUsage:  true,
		SilenceErrors: true,

		// PersistentPreRunE validates global flags before any subcommand runs.
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			if jqExpr != "" && !jsonOut {
				return fmt.Errorf("--jq requires --json")
			}
			return nil
		},
	}

	// Global flags — available to every subcommand.
	pf := cmd.PersistentFlags()
	pf.StringVar(&token, "token", "", "API token (overrides MYSERVICE_API_TOKEN env var)")
	pf.BoolVar(&jsonOut, "json", false, "Output raw JSON")
	pf.BoolVar(&plain, "plain", false, "Output tab-separated plain text (no headers)")
	pf.StringVar(&jqExpr, "jq", "", "Filter JSON output with a jq expression (requires --json)")

	// Register all subcommands.
	cmd.AddCommand(newStatusCmd())
	cmd.AddCommand(newReaderCmd())
	// cmd.AddCommand(newOtherCmd())

	return cmd
}

// getClient builds a Client from flags + env. Call this inside RunE.
func getClient(cmd *cobra.Command) (*client.Client, error) {
	token, _ := cmd.Flags().GetString("token")
	if token == "" {
		token = os.Getenv("MYSERVICE_API_TOKEN")
	}
	if token == "" {
		return nil, fmt.Errorf("missing API token: set --token or MYSERVICE_API_TOKEN")
	}
	return client.New(token), nil
}

// getFormatter builds a Formatter from the global output flags.
func getFormatter(cmd *cobra.Command) (*output.Formatter, error) {
	jsonOut, _ := cmd.Flags().GetBool("json")
	plain, _ := cmd.Flags().GetBool("plain")
	jqExpr, _ := cmd.Flags().GetString("jq")
	return output.New(jsonOut, plain, jqExpr)
}

// ExitCode maps an error to a stable integer exit code.
func ExitCode(err error) int {
	if err == nil {
		return ExitOK
	}

	// Check for typed errors from the client package.
	var apiErr *client.APIError
	if errors.As(err, &apiErr) {
		switch {
		case apiErr.StatusCode == 401 || apiErr.StatusCode == 403:
			return ExitAuth
		case apiErr.StatusCode == 404:
			return ExitNotFound
		}
	}

	return ExitError
}
```

**Rules:**
- **No `init()` functions.** No global `var rootCmd`. Everything is created by `NewRootCmd()`.
- `SilenceUsage` and `SilenceErrors` must both be `true`.
- `getClient()` and `getFormatter()` are unexported helpers, called from each subcommand's `RunE`.
- `--token` always falls back to `<SERVICE>_API_TOKEN` env var.
- `--jq` must require `--json` (validated in `PersistentPreRunE`).

---

## 4. Simple Command — `internal/cmd/status.go`

```go
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// newStatusCmd returns the "status" subcommand.
// Every command is a factory function — never a global var.
func newStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Check API connectivity and auth",
		RunE: func(cmd *cobra.Command, args []string) error {
			c, err := getClient(cmd)
			if err != nil {
				return err
			}

			f, err := getFormatter(cmd)
			if err != nil {
				return err
			}

			resp, err := c.GetStatus()
			if err != nil {
				return err
			}

			return f.Print(cmd.OutOrStdout(), resp)
		},
	}
}
```

---

## 5. Resource Group with Subcommands — `internal/cmd/reader.go`

```go
package cmd

import (
	"github.com/owner/your-cli/internal/client"
	"github.com/spf13/cobra"
)

// newReaderCmd groups reader-related subcommands.
// The parent command has no RunE — it just prints help.
func newReaderCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "reader",
		Short: "Manage reader documents",
	}

	cmd.AddCommand(newReaderListCmd())
	cmd.AddCommand(newReaderGetCmd())
	// cmd.AddCommand(newReaderUpdateCmd())

	return cmd
}

// newReaderListCmd lists documents with optional filters.
func newReaderListCmd() *cobra.Command {
	var params client.ListReaderParams

	cmd := &cobra.Command{
		Use:     "list",
		Short:   "List reader documents",
		Aliases: []string{"ls"}, // Required: every "list" command must alias "ls"
		RunE: func(cmd *cobra.Command, args []string) error {
			c, err := getClient(cmd)
			if err != nil {
				return err
			}

			f, err := getFormatter(cmd)
			if err != nil {
				return err
			}

			resp, err := c.ListReader(params)
			if err != nil {
				return err
			}

			return f.Print(cmd.OutOrStdout(), resp)
		},
	}

	// Flags use kebab-case and human-friendly names.
	// Match API brand terms, not internal field names.
	// Good: --updated-after    Bad: --updated_gt
	// Good: --category         Bad: --cat
	flags := cmd.Flags()
	flags.StringVar(&params.Category, "category", "", "Filter by category")
	flags.StringVar(&params.UpdatedAfter, "updated-after", "", "Only items updated after this date")
	flags.IntVar(&params.PageSize, "page-size", 0, "Number of results per page")

	return cmd
}

// newReaderGetCmd fetches a single document by ID.
func newReaderGetCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "get <id>",
		Short: "Get a reader document by ID",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			c, err := getClient(cmd)
			if err != nil {
				return err
			}

			f, err := getFormatter(cmd)
			if err != nil {
				return err
			}

			resp, err := c.GetReader(args[0])
			if err != nil {
				return err
			}

			return f.Print(cmd.OutOrStdout(), resp)
		},
	}
}
```

**Rules:**
- Subcommand naming must match the API's brand terms (e.g., if the API calls it "Reader", use `reader`, not `document`).
- Every `list` subcommand must have `Aliases: []string{"ls"}`.
- Flags use **kebab-case** and human-friendly names (`--updated-after`, not `--updated_gt`).
- Params struct is bound to flags directly — no manual map building.
- For update commands, use `cmd.Flags().Changed("field-name")` to detect which fields were explicitly set.

---

## 6. Client — `internal/client/client.go`

```go
package client

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"

	"github.com/owner/your-cli/internal/model"
)

const baseURL = "https://api.myservice.com/v1"

// APIError represents an HTTP error response from the API.
type APIError struct {
	StatusCode int
	Message    string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("API error %d: %s", e.StatusCode, e.Message)
}

// Client wraps HTTP calls to the MyService API.
type Client struct {
	token  string
	http   *http.Client
}

// New creates a Client with the given API token.
func New(token string) *Client {
	return &Client{
		token: token,
		http:  &http.Client{},
	}
}

// ListReaderParams holds optional filters for listing reader documents.
type ListReaderParams struct {
	Category     string
	UpdatedAfter string
	PageSize     int
}

// encode converts params to URL query values. Only set fields are included.
func (p ListReaderParams) encode() url.Values {
	v := url.Values{}
	if p.Category != "" {
		v.Set("category", p.Category)
	}
	if p.UpdatedAfter != "" {
		v.Set("updated_after", p.UpdatedAfter)
	}
	if p.PageSize > 0 {
		v.Set("page_size", strconv.Itoa(p.PageSize))
	}
	return v
}

// ListReader fetches reader documents with optional filters.
func (c *Client) ListReader(params ListReaderParams) (*model.PaginatedResponse[model.Reader], error) {
	u := baseURL + "/reader/?" + params.encode().Encode()
	var result model.PaginatedResponse[model.Reader]
	if err := c.get(u, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// GetReader fetches a single reader document by ID.
func (c *Client) GetReader(id string) (*model.Reader, error) {
	u := baseURL + "/reader/" + id
	var result model.Reader
	if err := c.get(u, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// GetStatus checks API connectivity and auth.
func (c *Client) GetStatus() (*model.Status, error) {
	u := baseURL + "/status"
	var result model.Status
	if err := c.get(u, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// get performs an authenticated GET request and decodes JSON.
func (c *Client) get(url string, out interface{}) error {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Token "+c.token)

	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return &APIError{StatusCode: resp.StatusCode, Message: string(body)}
	}

	return json.NewDecoder(resp.Body).Decode(out)
}
```

**Rules:**
- Params structs live next to the client methods that use them.
- Each params struct has an `encode() url.Values` method.
- Client methods accept the params struct directly.
- `APIError` is a typed error so `ExitCode()` can pattern-match on it.

---

## 7. Models — `internal/model/`

### `internal/model/reader.go`

```go
package model

// Reader represents a reader document from the API response.
// Every field MUST have a json tag matching the API's field name.
type Reader struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Author    string `json:"author"`
	Category  string `json:"category"`
	URL       string `json:"url"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

// CreateReaderRequest is used for creating a new reader document.
// Request structs use omitempty so zero values are not sent.
type CreateReaderRequest struct {
	URL      string `json:"url"`
	Title    string `json:"title,omitempty"`
	Author   string `json:"author,omitempty"`
	Category string `json:"category,omitempty"`
}

// UpdateReaderRequest is used for partial updates.
// Pointer fields distinguish "not set" (nil) from "set to empty string".
type UpdateReaderRequest struct {
	Title    *string `json:"title,omitempty"`
	Author   *string `json:"author,omitempty"`
	Category *string `json:"category,omitempty"`
}
```

### `internal/model/common.go`

```go
package model

// PaginatedResponse wraps paginated API responses.
// Use Go generics so every list endpoint gets type safety.
type PaginatedResponse[T any] struct {
	Count    int    `json:"count"`
	NextPage string `json:"next_page,omitempty"`
	Results  []T    `json:"results"`
}

// Status represents the API status/health response.
type Status struct {
	OK       bool   `json:"ok"`
	Username string `json:"username"`
}
```

**Rules:**
- Response structs: every field has a `json:"snake_case"` tag.
- Create/request structs: use `omitempty` on optional fields.
- Update structs: use `*string` (pointer) + `omitempty` so nil means "don't change".
- Use `PaginatedResponse[T]` generic for all list endpoints.

---

## 8. Output Formatter — `internal/output/output.go`

```go
package output

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"text/tabwriter"

	"github.com/itchyny/gojq"
)

// Formatter controls output rendering based on --json, --plain, --jq flags.
type Formatter struct {
	jsonOut bool
	plain   bool
	jqQuery *gojq.Query // nil when --jq is not set
}

// New creates a Formatter. If jqExpr is non-empty, it is compiled here.
func New(jsonOut, plain bool, jqExpr string) (*Formatter, error) {
	f := &Formatter{jsonOut: jsonOut, plain: plain}
	if jqExpr != "" {
		q, err := gojq.Parse(jqExpr)
		if err != nil {
			return nil, fmt.Errorf("invalid jq expression: %w", err)
		}
		f.jqQuery = q
	}
	return f, nil
}

// Print writes data to w. JSON mode outputs raw or jq-filtered JSON.
// Plain mode outputs tab-separated values. Default mode is the same as plain
// but may include headers or formatting.
func (f *Formatter) Print(w io.Writer, data interface{}) error {
	if f.jsonOut {
		return f.printJSON(w, data)
	}
	if f.plain {
		return f.printPlain(w, data)
	}
	// Default: same as plain with headers (customize per project).
	return f.printPlain(w, data)
}

// Hint writes a message to stderr. Use for progress, tips, or non-data output.
func (f *Formatter) Hint(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
}

// PrintMessage writes a simple message to w. Use for confirmations like
// "Document created" that are not structured data.
func (f *Formatter) PrintMessage(w io.Writer, msg string) error {
	if f.jsonOut {
		return json.NewEncoder(w).Encode(map[string]string{"message": msg})
	}
	_, err := fmt.Fprintln(w, msg)
	return err
}

func (f *Formatter) printJSON(w io.Writer, data interface{}) error {
	if f.jqQuery != nil {
		return f.applyJQ(w, data)
	}
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	return enc.Encode(data)
}

func (f *Formatter) applyJQ(w io.Writer, data interface{}) error {
	// Convert to interface{} via JSON round-trip for gojq compatibility.
	raw, err := json.Marshal(data)
	if err != nil {
		return err
	}
	var input interface{}
	if err := json.Unmarshal(raw, &input); err != nil {
		return err
	}

	iter := f.jqQuery.Run(input)
	for {
		v, ok := iter.Next()
		if !ok {
			break
		}
		if err, isErr := v.(error); isErr {
			return fmt.Errorf("jq error: %w", err)
		}
		out, err := json.Marshal(v)
		if err != nil {
			return err
		}
		fmt.Fprintln(w, string(out))
	}
	return nil
}

func (f *Formatter) printPlain(w io.Writer, data interface{}) error {
	tw := tabwriter.NewWriter(w, 0, 4, 2, ' ', 0)
	defer tw.Flush()

	// Use type switch to render known types as columns.
	// Each project customizes this for its own model types.
	switch v := data.(type) {
	default:
		// Fallback: marshal as JSON (should not happen in practice).
		_ = v
		enc := json.NewEncoder(tw)
		return enc.Encode(data)
	}
}
```

**Rules:**
- Must live in `internal/output/output.go`.
- Must use `itchyny/gojq` — not `os/exec` with external `jq`.
- Three methods: `Print()`, `Hint()`, `PrintMessage()`.
- `Hint()` always writes to stderr.
- `Print()` writes to the provided `io.Writer` (usually `cmd.OutOrStdout()`).

---

## 9. Test Structure

### Unit Test Example — `internal/client/client_test.go`

```go
package client_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/owner/your-cli/internal/client"
)

func TestGetStatus(t *testing.T) {
	// Spin up a local HTTP server that returns canned JSON.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/status" {
			t.Errorf("unexpected path: %s", r.URL.Path)
		}
		if r.Header.Get("Authorization") != "Token test-token" {
			t.Errorf("missing or wrong auth header")
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"ok":true,"username":"testuser"}`))
	}))
	defer srv.Close()

	c := client.NewWithBaseURL("test-token", srv.URL+"/v1")
	status, err := c.GetStatus()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !status.OK {
		t.Error("expected status.OK to be true")
	}
	if status.Username != "testuser" {
		t.Errorf("expected username 'testuser', got '%s'", status.Username)
	}
}
```

### BDD Directory Structure

```
tests/
└── bdd/
    ├── features/
    │   ├── status.feature
    │   ├── reader_list.feature
    │   └── reader_get.feature
    └── steps/
        ├── status_test.go
        ├── reader_list_test.go
        └── reader_get_test.go
```

**Rules:**
- Unit tests use `httptest.NewServer` for HTTP mocking — no external dependencies.
- Client should expose a `NewWithBaseURL()` constructor for testability.
- BDD tests live under `tests/bdd/` with `features/` and `steps/` subdirectories.
- At least one `_test.go` must exist before delivery.

---

## 10. go.mod Requirements

```
module github.com/owner/your-cli
```

**Rules:**
- Module path must be the full GitHub path: `github.com/<owner>/<repo>`.
- Never use a bare module name like `your-cli` or `myservice`.
- Required dependencies: `github.com/spf13/cobra` and `github.com/itchyny/gojq`.
