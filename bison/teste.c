#include <stdio.h>
#include <stdlib.h>

int main()
{
    float notas[26], pesos[26];
    int qtd_notas = 0, i = 0;
    float sum_notas = 0.0, sum_pesos = 0.0, nota_final, nota_necessaria, nota_af;

    int COM_PESO = 0;
    printf("Digite quantas notas você irá ler: ");
    scanf("%i", &qtd_notas);

    printf("Notas contém pesos? (SIM: 1 NÃO: 0): ");
    scanf("%i", &COM_PESO);

    while (qtd_notas <= 0)
    {
        printf("Digite quantas notas você irá ler: ");
        scanf("%i", &qtd_notas);
    }

    while (i != qtd_notas)
    {
        printf("Insira a nota %d (de %d): ", i + 1, qtd_notas);
        scanf("%f", &notas[i]);

        if (!(notas[i] < 0 || notas[i] > 10))
        {
            if (COM_PESO)
            {
                printf("Insira o peso da nota %d (de %d): ", i + 1, qtd_notas);
                scanf("%f", &pesos[i]);
                while (pesos[i] < 0)
                {
                    printf("Insira o peso da nota %d (de %d): ", i + 1, qtd_notas);
                    scanf("%f", &pesos[i]);
                }
            }
            i++;
        }
    }

    if (COM_PESO)
    {
        for (int i = 0; i < qtd_notas; i++)
        {
            sum_pesos += pesos[i];
            sum_notas += notas[i] * pesos[i];
        }
    }
    else
    {
        for (int i = 0; i < qtd_notas; i++)
        {
            sum_notas += notas[i];
        }
        sum_pesos = qtd_notas;
    }

    nota_final = sum_notas / sum_pesos;

    printf("Sua nota final é %f\n", nota_final);
    if (nota_final > 7.0)
    {
        printf("Parabéns!\n");
    }
    else
    {
        if (nota_final >= 3 && nota_final < 7.0)
        {
            nota_necessaria = 10 - nota_final;
            printf("Você ficou de AF! (Necessário tirar %f)\n", nota_necessaria);
            printf("Digite sua nota de AF: ");

            scanf("%f", &nota_af);
            if (nota_af >= nota_necessaria)
            {
                printf("Parabéns, você passou!");
            }
            else
            {
                printf("Infelizmente, você foi reprovado.");
            }
        }

        else
        {
            printf("Infelizmente, você foi reprovado.");
        }
    }

    return 0;
}