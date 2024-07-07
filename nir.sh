#!/bin/bash

# Numele fisierului care contine lista de produse si preturi de vanzare
FILE="produse.txt"
NIR_DIR="nirs"

# Functie pentru a citi numele produselor din fisier
read_products() {
    mapfile -t products < "$FILE"
    for i in "${!products[@]}"; do
        products[i]=$(echo "${products[i]%%:*}" | tr -d '\r')  # Extragem doar numele produsului pana la ":"
    done
}

# Functie pentru afisarea meniului de produse
display_menu() {
    clear
    echo "=== Adaugare NIR ==="
    local columns=$(tput cols)
    local column_width=40
    local num_columns=$((columns / column_width))
    local num_rows=$(( (${#products[@]} + num_columns - 1) / num_columns ))

    for row in $(seq 0 $((num_rows - 1))); do
        for col in $(seq 0 $((num_columns - 1))); do
            index=$((row + col * num_rows))
            if [[ $index -lt ${#products[@]} ]]; then
                if [[ $index -eq $current_index ]]; then
                    # Evidentiem produsul selectat cu culori inversate
                    printf "\e[7m%02d. %-35s\e[0m" "$((index+1))" "${products[$index]}"
                else
                    printf "%02d. %-35s" "$((index+1))" "${products[$index]}"
                fi
            fi
        done
        echo ""
    done

    display_nir

    echo "========================================================="
    echo "Apasati 'Enter' pentru a adauga produsul in NIR."
    echo "Apasati '+' pentru a adauga cantitate, '-' pentru a reduce cantitate."
    echo "Apasati 'p' pentru a finaliza si salva NIR-ul."
    echo "Apasati 'q' pentru a iesi fara a salva."
    echo "Apasati 'l' pentru a lista ultimul NIR salvat."
    echo "Apasati 'x' pentru a anula NIR-ul curent."
}

# Functie pentru afisarea continutului NIR-ului
display_nir() {
    local total_general=0
    echo ""
    echo "=== Continut NIR ==="
    for item in "${nir[@]}"; do
        local product_name=$(echo "$item" | cut -d':' -f1)
        local quantity=$(echo "$item" | cut -d':' -f2)
        local purchase_price=$(echo "$item" | cut -d':' -f3)
        local line_total=$(echo "scale=2; $quantity * $purchase_price" | bc)
        total_general=$(echo "scale=2; $total_general + $line_total" | bc)
        printf "%s: %d x %.2f = %.2f\n" "$product_name" "$quantity" "$purchase_price" "$line_total"
    done
    echo "Total NIR = $total_general"
    echo ""
}

# Functie pentru a adauga un produs in NIR cu pret de achizitie (cu doua zecimale)
add_to_nir() {
    local product="${products[$current_index]}"
    local product_entry="$(printf "%s" "$product")"
    local product_purchase_price

    # Verificam daca produsul este deja in NIR
    for i in "${!nir[@]}"; do
        if [[ "${nir[$i]%%:*}" == "$product_entry" ]]; then
            # Daca da, incrementam cantitatea
            local current_qty=$(echo "${nir[$i]}" | awk -F: '{print $2}')
            local product_purchase_price=$(echo "${nir[$i]}" | awk -F: '{print $3}')
            local new_qty=$((current_qty + 1))
            nir[$i]="${product_entry}:${new_qty}:${product_purchase_price}"
            return
        fi
    done

    # Daca nu, adaugam produsul cu cantitate 1 si pret de achizitie
    while true; do
        echo -n "Introduceti pretul de achizitie pentru $product (cu doua zecimale): "
        read -r product_purchase_price

        # Validam ca pretul de achizitie sa contina doar cifre si doua zecimale
        if [[ "$product_purchase_price" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
            break
        else
            echo "Pretul de achizitie introdus nu este valid. Introduceti un numar valid (cu doua zecimale)."
        fi
    done

    nir+=("${product_entry}:1:${product_purchase_price}")
}

# Functie pentru reducerea cantitatii unui produs din NIR
reduce_from_nir() {
    local product="${products[$current_index]}"
    local product_entry="$(printf "%s" "$product")"

    # Verificam daca produsul este in NIR
    for i in "${!nir[@]}"; do
        if [[ "${nir[$i]%%:*}" == "$product_entry" ]]; then
            # Daca da, decrementam cantitatea
            local current_qty=$(echo "${nir[$i]}" | awk -F: '{print $2}')
            local product_purchase_price=$(echo "${nir[$i]}" | awk -F: '{print $3}')
            if [[ "$current_qty" -gt 1 ]]; then
                local new_qty=$((current_qty - 1))
                nir[$i]="${product_entry}:${new_qty}:${product_purchase_price}"
            else
                # Daca ajunge la 1, il stergem din NIR
                unset 'nir[i]'
            fi
            return
        fi
    done
}

# Functie pentru a salva NIR-ul intr-un fisier
save_nir() {
  if [ ${#nir[@]} -gt 0 ]; then 
    local timestamp=$(date +%Y%m%d%H%M%S)
    local nir_file="${NIR_DIR}/nir_${timestamp}.txt"
    
    echo -n "Introduceti numarul documentului NIR: "
    read -r document_number
    echo -n "Introduceti numele furnizorului: "
    read -r supplier_name
    supplier_name=$(echo "$supplier_name" | tr '[:lower:]' '[:upper:]')  # Convertim furnizorul in majuscule
    echo -n "Introduceti data documentului (YYYY-MM-DD, apasati Enter pentru data curenta): "
    read -r document_date

    if [[ -z "$document_date" ]]; then
        document_date=$(date +%Y-%m-%d)
    fi

    echo "${document_number}:${supplier_name}:${document_date}" > "$nir_file"
    for item in "${nir[@]}"; do
        echo "$item" >> "$nir_file"
    done

    echo "NIR-ul a fost salvat in ${nir_file}."
  fi
}

# Functie pentru listarea ultimului NIR salvat
list_last_nir() {
    local last_nir_file=$(ls -1t "${NIR_DIR}/nir_"*.txt 2>/dev/null | head -n1)
    if [[ -n "$last_nir_file" ]]; then
        echo "Ultimul NIR salvat:"
        echo "============================================="
        cat "$last_nir_file"
        echo "============================================="
        local total_general=$(awk -F':' 'NR > 1 { sum += $2 * $3 } END { printf "Total NIR = %.2f\n", sum }' "$last_nir_file")
        echo "$total_general"
    else
        echo "Nu exista niciun NIR salvat."
    fi
}

# Functie pentru anularea NIR-ului curent
cancel_nir() {
    echo "NIR-ul curent a fost anulat."
    nir=()
}

# Functie pentru a valida ca un input contine doar cifre
validate_digits() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Initializam indexul curent si NIR-ul
current_index=0
nir=()

# Citim numele produselor din fisier
read_products

# Cream directorul NIR daca nu exista
mkdir -p "$NIR_DIR"

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
            add_to_nir
            ;;
        '+')
            add_to_nir
            ;;
        '-')
            reduce_from_nir
            ;;
        p)
            save_nir
            nir=()
            ;;
        q)
            echo "Iesire fara a salva NIR-ul..."
            break
            ;;
        l)
            list_last_nir
            echo "Apasati orice tasta pentru a continua..."
            read -rsn1
            ;;
        x)
            cancel_nir
            ;;
        *)
            if [[ "$input" =~ [0-9] ]]; then
                read -rsn1 input2
                if [[ "$input2" =~ [0-9] ]]; then
                    input+="$input2"
                    if [[ "$input" =~ ^[0-9]{2}$ ]]; then
                        index=$((10#"$input" - 1))
                        if [[ $index -ge 0 && $index -lt ${#products[@]} ]]; then
                            current_index=$index
                        fi
                    fi
                fi
            fi
            ;;
    esac
    display_menu
done

echo "Program inchis."
