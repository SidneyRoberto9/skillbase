---
name: merge
description: Use ao sincronizar as branches de saída (homolog ou config/zull-implementation, e main) a partir da develop, ou quando o usuário pedir /merge.
---

# Merge

Propaga `origin/develop` em cadeia, com push em cada passo:

```
origin/develop → homologação → main
```

Homologação é toda branch que existir no `origin` entre `homolog` e
`config/zull-implementation` (nome antigo, ainda usado em projetos não
renomeados). Se as duas existirem, as duas recebem a develop e as duas entram
na main.

Toda a lógica está em `merge.sh`. Não reescrever os passos à mão.

## Como rodar

Na raiz do repositório:

```bash
bash ~/.claude/skills/merge/merge.sh
```

Se o diretório atual não for um repositório git mas contiver repositórios
(ex.: `<projeto>-api` e `<projeto>-ui`), rodar uma vez em cada um:

```bash
(cd <repo> && bash ~/.claude/skills/merge/merge.sh)
```

## Saída

| Linha | Significado |
|---|---|
| `PARADO — ...` | Pré-condição falhou (sem `develop`, sem `main`, sem branch de homologação, sem `origin`). Nada foi tocado. |
| `OK: <alvo> ← <origem>` | Merge e push feitos. |
| `DIVERGIU: <alvo> ← <origem>` | A branch local tem commits que não estão no `origin` (à frente ou divergente). Nada foi enviado para esse alvo e a cadeia parou. |
| `FALHA <etapa>: <alvo> ...` | Worktree, fast-forward (ex.: alterações não commitadas), merge ou push falhou. A cadeia parou; se foi na homologação, a `main` não foi tocada. |

Exit 0 só quando todos os passos deram `OK`. No fim, o script lista os SHAs de
`origin/<branch>`.

Reportar ao usuário, por repositório, as linhas `OK`/`DIVERGIU`/`FALHA`/`PARADO`
e os SHAs finais.

## Regras

- Conflito é sempre resolvido pelo script com `-X theirs` (a origem vence). Nunca
  resolver na mão.
- `DIVERGIU`, `FALHA` ou `PARADO`: reportar e parar. Nunca contornar com
  `reset`, `push --force` ou edição do script.
- Nunca tocar na branch `develop`.

## Auto-teste

```bash
bash ~/.claude/skills/merge/test.sh
```

Monta repositórios descartáveis e confere a cadeia: com `homolog`, com o alvo
sendo a branch atual, só com `config/zull-implementation`, sem homologação, e
com a homologação local divergente e com a `main` local à frente do `origin`.
Termina com `ALL PASS`.
