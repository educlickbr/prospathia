/**
 * Utilitários de Cálculo do Exame VVS (Otolithics)
 * 
 * Responsabilidades PURAS (sem side-effects, sem Supabase):
 *  - Sortear sequência de direções (esquerda/direita)
 *  - Gerar medidas angulares de uma condição de exame
 */

/** Item de direção numa sequência sorteada */
export interface DirecaoItem {
    ordem: number;
    direcao: 'e' | 'd';
}

/** Parâmetros de uma condição de exame vindos do banco via BFF */
export interface CondicaoExame {
    id: string;
    nome: string;
    label: string;
    cod_condicao: number;
    amaxdir: number;
    amaxesq: number;
    amindir: number;
    aminesq: number;
    aidealcab: number;
    amincab: number;
    amaxcab: number;
    created_at?: string;
}

/** Uma medida gerada para o exame */
export interface MedidaExame {
    cod_medicao_condicao: number;
    cod_medicao: number;
    direcao: 'e' | 'd';
    angulo: number;
    nome_condicao: string;
    cod_condicao: number;
    id_condicao: string;
    aidealcab: number;
    amincab: number;
    amaxcab: number;
}

// ─── Sequências de Direção Pré-Definidas ────────────────────────────────────

const ORDENS_DIRECAO: DirecaoItem[][] = [
    [{ ordem: 1, direcao: 'e' }, { ordem: 2, direcao: 'e' }, { ordem: 3, direcao: 'd' }, { ordem: 4, direcao: 'd' }],
    [{ ordem: 1, direcao: 'e' }, { ordem: 2, direcao: 'd' }, { ordem: 3, direcao: 'e' }, { ordem: 4, direcao: 'd' }],
    [{ ordem: 1, direcao: 'e' }, { ordem: 2, direcao: 'd' }, { ordem: 3, direcao: 'd' }, { ordem: 4, direcao: 'e' }],
    [{ ordem: 1, direcao: 'd' }, { ordem: 2, direcao: 'e' }, { ordem: 3, direcao: 'e' }, { ordem: 4, direcao: 'd' }],
    [{ ordem: 1, direcao: 'd' }, { ordem: 2, direcao: 'd' }, { ordem: 3, direcao: 'e' }, { ordem: 4, direcao: 'e' }],
    [{ ordem: 1, direcao: 'd' }, { ordem: 2, direcao: 'e' }, { ordem: 3, direcao: 'd' }, { ordem: 4, direcao: 'e' }],
];

/**
 * Sorteia UMA sequência aleatória de esquerda/direita entre as 6 possíveis.
 */
export function sortearOrdemDirecao(): DirecaoItem[] {
    const indice = Math.floor(Math.random() * ORDENS_DIRECAO.length);
    return ORDENS_DIRECAO[indice];
}

// ─── Gerador de Ângulos ──────────────────────────────────────────────────────

const MIN_DIFERENCA = 10;

/**
 * Sorteia um ângulo válido dentro do intervalo [min, max]
 * garantindo que a distância mínima `MIN_DIFERENCA` seja respeitada
 * em relação a todos os ângulos já sorteados no mesmo lado.
 */
function sorteiaAngulo(min: number, max: number, jaSorteados: number[]): number {
    const possiveis: number[] = [];

    for (let valor = min; valor <= max; valor++) {
        if (jaSorteados.every(prev => Math.abs(valor - prev) >= MIN_DIFERENCA)) {
            possiveis.push(valor);
        }
    }

    if (possiveis.length === 0) {
        // Fallback: escolhe o valor com maior distância mínima dos sorteados
        let melhor = min;
        let maiorDist = 0;
        for (let valor = min; valor <= max; valor++) {
            const menorDist = jaSorteados.length
                ? Math.min(...jaSorteados.map(prev => Math.abs(valor - prev)))
                : 999;
            if (menorDist > maiorDist) {
                maiorDist = menorDist;
                melhor = valor;
            }
        }
        return melhor;
    }

    return possiveis[Math.floor(Math.random() * possiveis.length)];
}

/**
 * Gera as 4 medidas angulares de UMA condição de exame,
 * respeitando a sequência de direções sorteada.
 *
 * @param condicao  - Objeto da condição (ex: neutra, haptica_direita)
 * @param ordem     - Resultado de `sortearOrdemDirecao()`
 */
export function gerarMedidasCondicao(
    condicao: CondicaoExame,
    ordem: DirecaoItem[]
): MedidaExame[] {
    const sorteadosE: number[] = [];
    const sorteadosD: number[] = [];

    return ordem.map((item, idx) => {
        let angulo: number;

        if (item.direcao === 'e') {
            angulo = sorteiaAngulo(condicao.aminesq, condicao.amaxesq, sorteadosE);
            sorteadosE.push(angulo);
        } else {
            angulo = sorteiaAngulo(condicao.amindir, condicao.amaxdir, sorteadosD);
            sorteadosD.push(angulo);
        }

        const cod_medicao = idx + 1;

        return {
            cod_medicao_condicao: cod_medicao,
            cod_medicao,
            direcao: item.direcao,
            angulo,
            nome_condicao: condicao.label,
            cod_condicao: condicao.cod_condicao,
            id_condicao: condicao.id,
            aidealcab: condicao.aidealcab,
            amincab: condicao.amincab,
            amaxcab: condicao.amaxcab,
        };
    });
}
