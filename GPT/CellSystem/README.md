# Cell System Prototype

Protótipo inicial da arquitetura unificada de células.

Objetivo:
- Centralizar criação e registro de células.
- Separar existência da célula de comportamento.
- Permitir que player e organismos usem a mesma base futuramente.

Estrutura planejada:

CellManager -> controla população e criação.
Cell -> organismo individual.
CellAI -> comportamento (caçar, fugir, vagar).
CellCombat -> interação por contato.
CellGenetics -> características herdadas.
