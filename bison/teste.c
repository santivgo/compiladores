#include <stdio.h>
#include <stdlib.h>

int main(){
    float n1[26], pesos[26];
    int qtd_notas = 0, i = 0;

    int PESO_PADRAO = 0;
    printf("Digite quantas notas você irá ler?");
    scanf("%i", &qtd_notas);

    printf("Sem pesos? (SIM: 1 NÃO: 0)");
    scanf("%d", PESO_PADRAO);


    while(qtd_notas <= 0){
        printf("Digite quantas notas você irá ler: ");
        scanf("%i", &qtd_notas);
    }


    while(i != qtd_notas){
        printf("Insira a nota %d (de %d)", i+1, qtd_notas);
        scanf("%f", &n1[i]);
        printf("Insira o peso da nota %d (de %d)", i+1, qtd_notas);
        scanf("%f", &n1[i]);

        i++;    
    }



    return 0;
}