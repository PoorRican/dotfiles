#                 ██
#                ░██
#  ██████  ██████░██
# ░░░░██  ██░░░░ ░██████
#    ██  ░░█████ ░██░░░██
#   ██    ░░░░░██░██  ░██
#  ██████ ██████ ░██  ░██
# ░░░░░░ ░░░░░░  ░░   ░░
#
#  ▓▓▓▓▓▓▓▓▓▓
# ░▓ author ▓ xero <x@xero.nu>
# ░▓ code   ▓ http://code.xero.nu/dotfiles
# ░▓ mirror ▓ http://git.io/.files
# ░▓▓▓▓▓▓▓▓▓▓
# ░░░░░░░░░░

#█▓▒░ pick a random number
_RAND=`shuf -i1-2 -n1`

#█▓▒░ display a random ascii banner
case $_RAND in
1)
  clear
  cat << X0
[38;5;208m  ._  _______ ._ _______ ._ _______ ._ _______
 ._╲╲╲   __  ╲_╲╲╲  __  ╲_╲╲╲  __  ╲_╲╲╲__.   ╲
  ╲      ‾╱   ╲     ‾╱   ╲     ‾╱   ╲    ╱  __╱ 
[38;5;214m  ╱   ╲  ╱    ╱╲    ╱    ╱╲    ╱    ╱╱  \╲  ‾ ╲_ 
  ╲    ╲_____╱ ╲╲_______╱ ╲╲_______╱ ╲╲___╲    ╱
   ╲   ╱‾‾‾‾    ‾‾‾‾‾‾‾    ‾‾‾‾‾‾‾     ‾‾‾ ╲__╱
    ╲_╱                                     ‾
[38;5;208m     ‾ ._ _______       _ ______   _ _______   _ _______     
       .╲╲╲__.   ╲  ╱^╲ ╲╲╲     ╲  ╲╲╲  ___ ╲__╲╲╲  _.  ╲   
        ╲   ╱  __╱  ╲_╱ ╱   ╲___╱  ╲    ‾‾   ╲      ╱    ╲   
        ╱  \╲  ‾ ╲_╱ . ╲╲    ‾‾ ╲_ ╱    ╱    ╱╲    ╱     ╱   
[38;5;214m        ╲╲___╲    :╲___╱ ╲_______╱ ╲╲__╱╲╲__╱  ╲╲__╲    ╱   
          ‾‾  ╲__╱  ‾‾    ‾‾‾‾‾‾    ‾‾   ‾‾     ‾‾  ╲__╱   
               ‾[0m
X0
;;
2)
  clear
  cat << X0
[38;5;208m  ._  _______ ._ _______ ._ _______ ._ _______
 ._╲╲╲   __  ╲_╲╲╲  __  ╲_╲╲╲  __  ╲_╲╲╲__.   ╲
  ╲      ‾╱   ╲     ‾╱   ╲     ‾╱   ╲    ╱  __╱ 
[38;5;214m  ╱   ╲  ╱    ╱╲    ╱    ╱╲    ╱    ╱╱  \╲  ‾ ╲_ 
  ╲    ╲_____╱ ╲╲_______╱ ╲╲_______╱ ╲╲___╲    ╱
   ╲   ╱‾‾‾‾    ‾‾‾‾‾‾‾    ‾‾‾‾‾‾‾     ‾‾‾ ╲__╱
    ╲_╱                                     ‾
[38;5;208m     ‾ ._ _______       _ ______   _ _______   _ _______     
       .╲╲╲__.   ╲  ╱^╲ ╲╲╲     ╲  ╲╲╲  ___ ╲__╲╲╲  _.  ╲   
        ╲   ╱  __╱  ╲_╱ ╱   ╲___╱  ╲    ‾‾   ╲      ╱    ╲   
        ╱  \╲  ‾ ╲_╱ . ╲╲    ‾‾ ╲_ ╱    ╱    ╱╲    ╱     ╱   
[38;5;214m        ╲╲___╲    :╲___╱ ╲_______╱ ╲╲__╱╲╲__╱  ╲╲__╲    ╱   
          ‾‾  ╲__╱  ‾‾    ‾‾‾‾‾‾    ‾‾   ‾‾     ‾‾  ╲__╱   
               ‾[0m
X0
;;
esac
