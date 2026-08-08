# CORE LOOP — Alive Cells

Bom, agora vamos limitar esse negócio antes que ele vire um monstro. 😭

A ideia central do jogo é simples:

> **sobreviver → coletar recursos → conseguir energia/material suficiente → fazer mitose → escolher uma mutação → continuar a run.**

O tema da feira é **material genético**, então o jogo precisa mostrar isso de verdade, e não simplesmente colocar um desenho de DNA no canto da tela.

## A ideia

O jogador controla uma célula em um campo aberto. Existem recursos espalhados pelo mapa e ameaças — células hostis e/ou vírus — que tornam a sobrevivência difícil.

O objetivo da run é sobreviver o máximo possível e conseguir recursos suficientes para realizar uma **mitose**.

Quando a mitose acontece, aparece uma tela de mutação. O jogador escolhe uma mutação pré-definida, que altera alguma característica da célula para a próxima etapa da run.

Assim temos uma relação simples entre:

**material genético → mutação → característica → gameplay.**

## Loop principal

```text
		SOBREVIVER
			 ↓
	  COLETAR RECURSOS
			 ↓
	  RECURSOS SUFICIENTES?
		  ↙       ↘
		NÃO       SIM
		 ↓         ↓
	  continuar   MITOSE
					 ↓
			  ESCOLHER MUTAÇÃO
					 ↓
			  NOVA GERAÇÃO
					 ↓
				 SOBREVIVER
```

## Genoma

Não precisamos começar simulando uma molécula de DNA inteira. Para o protótipo, o “genoma” pode ser representado por alguns valores que determinam características da célula.

Exemplo:

```text
Velocidade:   0.65
Resistência:  0.40
Absorção:     0.80
Reprodução:   0.50
```

Uma mutação altera um desses valores.

Exemplo:

```text
Velocidade
0.65 → 0.75
```

O importante é que a alteração genética tenha uma consequência visível no jogo.

## Tela de mutação

Depois da mitose, o jogador pode escolher entre algumas mutações pré-definidas.

Algo simples, por exemplo:

```text
		MUTAÇÃO

[+] Velocidade
[+] Resistência
[+] Absorção

	   ESCOLHER
```

Não precisamos fazer dezenas de mutações. Algumas boas e bem explicadas são melhores do que um sistema gigantesco que não terminaremos.

## Tempo de vida

A run terá um contador de tempo vivo.

Exemplo:

```text
TEMPO DE VIDA: 02:37
RECURSOS: 84
GERAÇÃO: 4
```

Isso também dá uma maneira simples de comparar runs.

## Células proceduralmente geradas

Essa é uma parte que **PODE** ficar muito ambiciosa, então a ideia é começar pequeno.

Todas as células podem receber características visuais geradas a partir de alguns parâmetros:

```text
forma
cor
tamanho
núcleo
padrão
```

A primeira versão pode usar somente:

```text
forma + cor + tamanho
```

Depois, se houver tempo:

```text
+ núcleo
+ padrão
```

A ideia mais interessante é que o visual da célula possa estar relacionado ao seu genoma. Assim, quando uma mutação altera uma característica, a célula pode também apresentar uma diferença visual.

## Ameaças

O mapa pode possuir ameaças espalhadas aleatoriamente.

Inicialmente, não precisamos de muitos tipos:

- célula hostil;
- vírus.

A geração procedural das ameaças deve ser simples. Não precisamos criar um ecossistema inteiro.

## O que NÃO fazer agora

Para não transformar o projeto em algo impossível para uma equipe iniciante e com pouco tempo:

- não simular uma célula biologicamente completa;
- não criar dezenas de tipos celulares;
- não criar um sistema genético extremamente complexo;
- não fazer um mapa procedural gigantesco antes do loop principal funcionar;
- não criar IA sofisticada sem necessidade;
- não adicionar mecânicas só porque parecem legais.

Se uma ideia não ajuda diretamente o loop principal ou a demonstração de material genético, ela pode esperar.

## Prioridade

### Nível 1 — obrigatório

- jogador se movimenta;
- recursos podem ser coletados;
- ameaças existem;
- jogador pode sobreviver/morrer;
- existe uma condição para realizar mitose;
- tela de mutação;
- algumas mutações realmente alteram características.

### Nível 2 — desejável

- contador de tempo vivo;
- geração visual procedural simples das células;
- genoma representado por valores;
- diferentes ameaças;
- herança do genoma entre gerações.

### Nível 3 — se sobrar tempo

- DNA visual;
- mutações mais complexas;
- geração procedural mais avançada;
- mais tipos de células/vírus;
- efeitos visuais ligados ao genoma;
- sistemas biológicos adicionais.

## Regra de ouro

> **Terminar um jogo pequeno é melhor do que terminar 30% de um jogo gigantesco.**

O objetivo é aparecer na feira com uma experiência jogável, compreensível e relacionada ao tema de **material genético**.

Se conseguirmos fazer isso bem, já está ótimo.
