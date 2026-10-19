# Prova Finale di Reti Logiche 2025/2026

Politecnico di Milano · Reti Logiche · **Voto: 26/30**

Componente hardware descritto in **VHDL** che legge da memoria una sequenza di numeri, la elabora con un **filtro a 3 o 5 coefficienti**, normalizza il risultato e lo riscrive in memoria.

## Cosa fa il componente

1. Legge la configurazione dalla memoria, a partire dall'indirizzo ricevuto su `i_add`:
   - `K1` e `K2`: concatenati danno `K`, la lunghezza della sequenza;
   - il bit meno significativo di `S`: sceglie il filtro, di ordine 3 o di ordine 5;
   - 14 coefficienti: 7 per il filtro di ordine 3 e 7 per quello di ordine 5.
2. Legge uno alla volta i `K` valori in ingresso, mantenendo una **finestra scorrevole degli ultimi 8 valori**.
3. Per ogni valore calcola la somma pesata con i coefficienti del filtro scelto (accumulatore con segno a 20 bit).
4. Normalizza la somma con una combinazione di shift aritmetici a destra e scrive in memoria il risultato a 8 bit.
5. Alza `o_done` quando l'intera sequenza è stata elaborata.

## Interfaccia

| Segnale | Dir. | Descrizione |
|---|---|---|
| `i_clk` | in | clock (periodo di 20 ns) |
| `i_rst` | in | reset asincrono |
| `i_start` | in | avvia una nuova elaborazione |
| `i_add` (16 bit) | in | indirizzo di memoria della sequenza |
| `i_mem_data` (8 bit) | in | dato letto dalla memoria |
| `o_mem_addr` (16 bit) | out | indirizzo di memoria |
| `o_mem_data` (8 bit) | out | dato da scrivere |
| `o_mem_en` / `o_mem_we` | out | abilitazione memoria / abilitazione scrittura |
| `o_done` | out | elaborazione terminata |

## Progetto

Un unico `process` implementa una **macchina a stati finiti** con 15 stati (da `s0` a `s10`, più stati di attesa per la latenza della memoria e stati separati per il calcolo con filtro di ordine 3 e di ordine 5). La finestra, i coefficienti e i contatori sono segnali; le larghezze sono dimensionate per evitare overflow nell'accumulatore.

## File

- `10835369.vhd`: sorgente VHDL (entity `project_reti_logiche`)
- `10835369.pdf`: relazione del progetto con specifica, architettura, risultati di sintesi e casi di test

## Simulazione

Usa un qualsiasi simulatore VHDL oppure Vivado: aggiungi `10835369.vhd` come sorgente, collegalo a un testbench che simula la memoria e avvia la simulazione con clock a 20 ns.
