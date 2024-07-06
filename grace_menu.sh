#!/bin/bash
set +x
# Numele fisierului care contine lista de produse si preturi
FILE="produse.txt"

# Functie pentru a citi produsele si preturile din fisier
read_products() {
    mapfile -t products < "$FILE"
    for i in "${!products[@]}"; do
        products[i]=$(echo "${products[i]}" | tr -d '\r')
    done
}

# Functie pentru a extrage pretul dintr-un produs
get_price() {
    [[ $1 ]] && {
    local product_entry="$1"
    echo "$product_entry" | awk -F: '{print $2}' | awk -F\  '{print $1}'
    } || echo "0"
}

#Functie pentru fisare total cos
display_cos() {
    echo ""
    echo "=== Cosul de Cumparaturi ==="
    total="0"
    for item in "${cart[@]}"; do
        price=$(get_price "$item")
	total=$(echo "$total" + "$price" | bc)
        echo "$item"
    done
    printf "Total: %.2f RON\n" "$total"
    echo ""
}	


# Functie pentru a afisa meniul si cosul
display_menu() {
    clear
    echo "=== Meniu Produse ==="
    for i in "${!products[@]}"; do
        if [[ $i -eq $current_index ]]; then
            printf "> %02d. %s\n" "$((i+1))" "${products[i]}"
        else
            printf "  %02d. %s\n" "$((i+1))" "${products[i]}"
        fi
    done

    display_cos
    
    echo "Apasati sagetile sus/jos pentru a naviga, Enter pentru a adauga/scoate din cos."
    echo "Apasati doua cifre pentru a adauga/scoate produsul."
    echo "Apasati 'p' pentru a tipari cosul la casa de marcat."
    echo "Apasati 'q' pentru a iesi."
}

# Initializam cosul de cumparaturi si indexul curent
cart=()
current_index=0

# Citim produsele din fisier
read_products

# Afisam meniul initial
display_menu

# Bucla principala pentru a gestiona intrarile utilizatorului
while true; do
    read -rsn1 input
    case "$input" in
        $'\x1b') # Detectam tasta Esc
            read -rsn2 -t 0.1 input
            if [[ "$input" == "[A" ]]; then
                # Sageata sus
                ((current_index--))
                if [[ $current_index -lt 0 ]]; then
                    current_index=$(( ${#products[@]} - 1 ))
                fi
            elif [[ "$input" == "[B" ]]; then
                # Sageata jos
                ((current_index++))
                if [[ $current_index -ge ${#products[@]} ]]; then
                    current_index=0
                fi
            fi
            ;;
        '') # Detectam tasta Enter
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ " ${cart[*]} " == *" $product_entry "* ]]; then
                # Scoatem produsul din cos
                cart=("${cart[@]/$product_entry}")
            else
                # Adaugam produsul in cos
                cart+=("$product_entry")
            fi
            ;;
        [0-9]) # Detectam o cifra, pregatim sa citim a doua cifra
            read -rsn1 input2
            if [[ "$input2" =~ [0-9] ]]; then
                input+="$input2"
                if [[ "$input" =~ ^[0-9]{2}$ ]]; then
                    index=$((10#"$input" - 1))
                    if [[ $index -ge 0 && $index -lt ${#products[@]} ]]; then
                        product="${products[$index]}"
                        product_entry="$(printf "%02d. %s" "$((index+1))" "$product")"
                        if [[ " ${cart[*]} " == *" $product_entry "* ]]; then
                            # Scoatem produsul din cos
                            cart=("${cart[@]/$product_entry}")
                        else
                            # Adaugam produsul in cos
                            cart+=("$product_entry")
                        fi
                    fi
                fi
            fi
            ;;
        p) # Tiparim cosul
	    clear
            display_cos
            echo "============================="
            echo "Apasati orice tasta pentru a reveni la meniu."
            read -rsn1
            ;;
        q) # Iesim din program
            break
            ;;
    esac
    display_menu
done

clear
echo "Program inchis."
set +x
