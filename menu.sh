#!/bin/bash

# Numele fisierului care contine lista de produse si preturi
FILE="produse.txt"
SALES_DIR="vanzari"

# Asiguram ca directorul de vanzari exista
mkdir -p "$SALES_DIR"

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

# Functie pentru afisare cos si total
display_cos() {
    [[ ${#cart[@]} -gt 0 ]] && {  
      echo ""
      echo "=== Cosul de Cumparaturi ==="
      total="0"
      for product in "${!cart[@]}"; do
        quantity="${cart[$product]}"
        price=$(get_price "$product")
        total=$(echo "$total + $price * $quantity" | bc)
        echo "$product ($quantity)"
      done
      printf "Total: %.2f RON\n" "$total"
      echo ""
    } || {
	   echo ""
           echo "=== Cosul de Cumparaturi ==="
           echo ""
    }

}

save_sales() {
    if [[ ${#cart[@]} -gt 0 ]]; then
     local timestamp=$(date +"%Y%m%d%H%M%S")
     local sales_file="$SALES_DIR/vanzare_$timestamp.txt"
     {
        echo "=== Cosul de Cumparaturi ==="
        total="0"
        for product in "${!cart[@]}"; do
            quantity="${cart[$product]}"
            price=$(get_price "$product")
            total=$(echo "$total + $price * $quantity" | bc)
            echo "$product ($quantity)"
        done
        printf "Total: %.2f RON\n" "$total"
     } > "$sales_file"
    fi
}	

# Functie pentru a afisa meniul si cosul in coloane
display_menu() {
    clear
    echo "=== Meniu Produse ==="
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

    display_cos
    
    echo "Apasati sagetile sus/jos pentru a naviga, Enter pentru a adauga/scoate din cos."
    echo "Apasati doua cifre pentru a adauga/scoate produsul."
    echo "Apasati '+' pentru a adauga cantitate, '-' pentru a scadea cantitate, 'p' pentru a tipari cosul la casa de marcat, 'x' pentru anulare cos de cumparaturi."
    echo "Apasati 'l' pentru a afisa ultimul bon tiparit, 't' pentru a afisa totalul vanzarilor pe ziua curenta, 'T' pentru a afisa totalul vanzarilor pe luna curenta."
    echo "Apasati 'q' pentru a iesi."
}

# Functie pentru a calcula si afisa totalul vanzarilor pe ziua curenta
calculate_daily_total() {
    local today=$(date +"%Y%m%d")
    local daily_total=0

    for file in "$SALES_DIR"/vanzare_"$today"*.txt; do
        if [[ -f "$file" ]]; then
            local total=$(awk '/^Total:/ {print $2}' "$file")
            daily_total=$(echo "$daily_total + $total" | bc)
        fi
    done

    echo "Totalul vanzarilor pentru ziua curenta: $daily_total RON"
}

# Functie pentru a calcula si afisa totalul vanzarilor pe luna curenta
calculate_monthly_total() {
    local current_month=$(date +"%Y%m")
    local monthly_total=0

    for file in "$SALES_DIR"/vanzare_"$current_month"*.txt; do
        if [[ -f "$file" ]]; then
            local total=$(awk '/^Total:/ {print $2}' "$file")
            monthly_total=$(echo "$monthly_total + $total" | bc)
        fi
    done

    echo "Totalul vanzarilor pentru luna curenta: $monthly_total RON"
}

# Functie pentru a afisa ultimul cos de cumparaturi
display_last_cart() {
    local last_file=$(ls -t "$SALES_DIR"/*.txt 2>/dev/null | head -n 1)
    if [[ -n "$last_file" && -f "$last_file" ]]; then
        clear
        local file_time=$(stat -c %y "$last_file" | cut -d'.' -f1)
        echo "=== Ultimul Cos de Cumparaturi ==="
        echo "Data si ora vanzarii: $file_time"
        cat "$last_file"
        echo "============================="
        echo "Apasati orice tasta pentru a reveni la meniu."
        read -rsn1
    else
        echo "Nu exista un cos de cumparaturi salvat."
    fi
}

# Initializam cosul de cumparaturi si indexul curent
declare -A cart
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
            if [[ -n "${cart[$product_entry]}" ]]; then
                # Scoatem produsul din cos
                unset cart["$product_entry"]
            else
                # Adaugam produsul in cos
                cart["$product_entry"]=1
            fi
            ;;
        [0-9]) # Detectam o cifra, pregatim sa citim a doua cifra
            read -rsn1 input2
            if [[ "$input2" =~ [0-9] ]]; then
                input+="$input2"
                if [[ "$input" =~ ^[0-9]{2}$ ]]; then
                    index=$((10#"$input" - 1))
                    if [[ $index -ge 0 && $index -lt ${#products[@]} ]]; then
                        current_index=$index
                        product="${products[$index]}"
                        product_entry="$(printf "%02d. %s" "$((index+1))" "$product")"
                        if [[ -n "${cart[$product_entry]}" ]]; then
                            # Scoatem produsul din cos
                            unset cart["$product_entry"]
                        else
                            # Adaugam produsul in cos
                            cart["$product_entry"]=1
                        fi
                    fi
                fi
            fi
            ;;
        '+') # Adauga cantitate
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ -n "${cart[$product_entry]}" ]]; then
                cart["$product_entry"]=$((cart["$product_entry"] + 1))
            else
                cart["$product_entry"]=1
            fi
            ;;
        '-') # Scade cantitate
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ -n "${cart[$product_entry]}" ]]; then
                if [[ ${cart[$product_entry]} -gt 1 ]]; then
                    cart["$product_entry"]=$((cart["$product_entry"] - 1))
                else
                    unset cart["$product_entry"]
                fi
            fi
            ;;
	x) #anulare cos
	    clear
	    cart=()
	    display_cos
            ;;		
        p) # Tiparim cosul
            clear
            display_cos
	    save_sales
            echo "============================================="
            echo "Apasati orice tasta pentru a reveni la meniu."
            read -rsn1
	    cart=()
            ;;
	t) # Total vanzari pe ziua curenta
            clear
            calculate_daily_total
            echo "============================================="
            echo "Apasati orice tasta pentru a reveni la meniu."
            read -rsn1
            ;;
        T) # Total vanzari pe luna curenta
            clear
            calculate_monthly_total
            echo "============================================="
            echo "Apasati orice tasta pentru a reveni la meniu."
            read -rsn1
            ;;
	l) # Afisam ultimul cos de cumparaturi
            display_last_cart
            ;;
        q) # Iesim din program
            clear
	    calculate_daily_total
	    calculate_monthly_total
	    echo "Felicitari! Mult succes in continuare!"
	    echo "=============================================="
            echo "Apasati orice tasta pentru a iesi din program."
            read -rsn1
	    break
            ;;
    esac
    display_menu
done

echo "Program inchis."
