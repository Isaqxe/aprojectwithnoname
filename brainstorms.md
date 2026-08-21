# Alive Cells — Brainstorms

Arquivo para ideias ainda não decididas. Nada aqui deve ser tratado como requisito de implementação sem decisão posterior.

## Mapa procedural com biomas

A ideia é substituir o mapa estático por um microambiente procedural, representando diferentes regiões do nível molecular.

Cada bioma poderia possuir algumas propriedades simples:

- aparência própria;
- recursos predominantes ou exclusivos;
- ameaças predominantes;
- uma ou mais condições ambientais;
- possíveis modificadores sobre as células.

Exemplo conceitual:

```text
BIOMA A → recurso R1 + ameaça A + condição A
BIOMA B → recurso R2 + ameaça B + condição B
BIOMA C → recurso R3 + ameaça C + condição C
```

A geração poderia usar uma seed para manter a distribuição do mapa reproduzível.

O objetivo não é simular química real. A ideia é criar regiões diferentes o suficiente para que o jogador tenha motivos para explorar e para que certas características/mutações sejam úteis em ambientes específicos.

Possível cadeia de gameplay:

```text
ambiente
   ↓
recursos e ameaças
   ↓
pressão sobre a célula
   ↓
características úteis
   ↓
mutação
   ↓
adaptação
```

Essa ideia pode ajudar a conectar o survival loop com genética e hereditariedade.

## Medo — comportamento baseado na diferença de força

Ideia de comportamento para as células inimigas:

Quando uma célula inimiga detectar o Player dentro do seu campo de visão, ela compara suas próprias estatísticas com as estatísticas do Player.

Exemplo de estatísticas:

```text
HP
Dano
Velocidade
```

Uma medida simplificada de diferença poderia ser:

```text
medo = soma_dos_status_do_player - soma_dos_status_da_célula
```

Interpretação proposta:

```text
medo > 0
    ↓
Player é mais forte
    ↓
célula foge

medo <= 0
    ↓
célula não considera o Player mais forte
    ↓
comportamento normal de perseguição/ameaça
```

Fluxo desejado:

```text
Player entra no campo de visão
          ↓
      comparar stats
          ↓
   ┌──────┴──────┐
   ↓             ↓
Player mais     Player não é
forte           mais forte
   ↓             ↓
FUGIR           perseguir/
                comportamento normal
```

A intenção é fazer as células parecerem mais orgânicas: nem todo inimigo reage ao Player da mesma forma. Uma célula fraca poderia fugir de um Player muito desenvolvido, enquanto uma célula suficientemente forte poderia persegui-lo.

### Observação de design

A soma simples de atributos é apenas um primeiro protótipo. Futuramente pode ser necessário ponderar cada estatística, porque HP, dano e velocidade não necessariamente possuem o mesmo peso em combate.

Outra possibilidade é usar uma margem de segurança:

```text
medo > limiar
    → fugir
```

para evitar que uma diferença minúscula entre as células faça o comportamento alternar constantemente.

### Integração possível com o sistema atual

O sistema deveria ser acionado **somente quando o Player entra no campo de visão do inimigo**, reaproveitando o raio de visão que as células já possuem.

Isso evita transformar a comparação de estatísticas em uma operação contínua quando o Player está fora da percepção da célula.

> Ideia de design — não implementar ainda.
