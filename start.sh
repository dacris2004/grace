!/bin/bash

# Functie pentru afisarea meniului principal
show_menu() {
    clear
    echo "=== Meniu Principal ==="
    echo "1. Vanzari"
    echo "2. NIR (Documente de Intrare)"
    echo "3. Stocuri"
    echo "4. Produse"
    echo "q. Iesire"
    echo "======================="
    echo -n "Alegeti o optiune: "
}

while true; do
    show_menu
    read -rsn1 opt
    case "$opt" in
        1)
            ./menu.sh
            ;;
        2)
            ./nir.sh
            ;;
        3)
            ./stocuri.sh
            ;;
	4)
	    ./produse.sh
	    ;;
        q)
            echo "Iesire..."
            break
            ;;
        *)
            echo "Optiune invalida!"
            ;;
    esac
done

clear
echo "Program inchis."
