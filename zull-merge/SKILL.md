---
name: zull-merge
description: Propaga a branch develop para config/zull-implementation e main em paralelo (merge + push), com develop vencendo conflitos. Use ao sincronizar as branches de saída a partir da develop.
---

# Zull Merge Skill

## Objective

Propagar o conteúdo de `develop` para as duas branches de saída
`config/zull-implementation` e `main`, em paralelo, com push para o `origin`.

Comportamento tudo-ou-nada: se **qualquer** das três branches
(`develop`, `config/zull-implementation`, `main`) não existir no `origin`, o
fluxo é abortado antes de qualquer merge ou push.

Conflitos são sempre resolvidos a favor da `develop` (`-X theirs`), sem
intervenção manual.

## Step 0 — Pré-condições (abortar se falhar)

```bash
git rev-parse --is-inside-work-tree   # precisa ser repositório git
git remote get-url origin             # precisa ter remote 'origin'
```

Se algum falhar → PARAR e reportar o motivo. Não prosseguir.

## Step 1 — Fetch

```bash
git fetch origin --prune
```

## Step 2 — Validar as 3 branches no origin (tudo-ou-nada)

```bash
MISSING=""
for b in develop config/zull-implementation main; do
  git rev-parse --verify --quiet "origin/$b" >/dev/null || MISSING="$MISSING $b"
done
[ -z "$MISSING" ] || { echo "PARADO — branches ausentes no origin:$MISSING"; exit 1; }
```

Se houver qualquer branch ausente → **PARAR**, reportar quais faltam, não tocar
em nada.

## Step 3 — Merge + push dos dois alvos em paralelo

Fonte do merge é sempre `origin/develop` (estado pós-fetch), **nunca** a develop
local. A branch `develop` não é tocada.

### Tratamento da branch atual

`git worktree` não permite a mesma branch em dois lugares. Detectar a branch do
working tree principal:

```bash
CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
```

- Se `CURRENT` for um dos alvos (`config/zull-implementation` ou `main`):
  processar esse alvo **in-place** no tree principal (sem worktree); o outro vai
  para worktree.
- Caso contrário: ambos os alvos vão para worktree.

### Pipeline por alvo (worktree)

```bash
merge_target() {
  TARGET="$1"
  WT=$(mktemp -d)
  git worktree add "$WT" "$TARGET" || { echo "FALHA worktree: $TARGET"; rm -rf "$WT"; return 1; }
  if ! git -C "$WT" merge --ff-only "origin/$TARGET"; then
    echo "DIVERGIU: $TARGET (alvo divergiu do origin — pulado)"
    git worktree remove --force "$WT"
    return 1
  fi
  git -C "$WT" merge -X theirs --no-edit "origin/develop" || { echo "FALHA merge: $TARGET"; git worktree remove --force "$WT"; return 1; }
  git -C "$WT" push origin "$TARGET" || { echo "FALHA push: $TARGET"; git worktree remove --force "$WT"; return 1; }
  git worktree remove --force "$WT"
  echo "OK: $TARGET"
}
```

### Pipeline in-place (alvo == branch atual)

```bash
merge_inplace() {
  TARGET="$1"
  git merge --ff-only "origin/$TARGET" || { echo "DIVERGIU: $TARGET"; return 1; }
  git merge -X theirs --no-edit "origin/develop" || { echo "FALHA merge: $TARGET"; return 1; }
  git push origin "$TARGET" || { echo "FALHA push: $TARGET"; return 1; }
  echo "OK: $TARGET"
}
```

### Execução concorrente

Rodar os dois alvos em background e aguardar ambos. Exemplo (ambos via worktree):

```bash
merge_target config/zull-implementation &
P1=$!
merge_target main &
P2=$!
wait $P1; R1=$?
wait $P2; R2=$?
```

Se `CURRENT` for um alvo, rodar `merge_inplace "$CURRENT"` em primeiro plano e o
outro alvo via `merge_target ... &` em paralelo. Cada pipeline aborta apenas a si
mesmo se o alvo divergiu — o outro segue.

## Step 4 — Report final

Reportar, para cada alvo: `OK` (mergeado + push), `DIVERGIU` (pulado) ou
`FALHA`. Listar os SHAs finais:

```bash
git rev-parse origin/config/zull-implementation origin/main
```

## Hard rules

- Faltando **qualquer** das 3 branches → parar antes de qualquer merge/push.
- Conflito nunca pede intervenção: `-X theirs` resolve sempre a favor da develop.
- **Nunca** tocar na branch `develop` — só leitura via `origin/develop`.
- Sempre limpar worktrees (`git worktree remove --force`), inclusive em erro.
- Fonte do merge é `origin/develop` (pós-fetch), não a develop local.
- Working tree principal deve terminar na mesma branch em que começou.
