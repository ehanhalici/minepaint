// M_PI tanımlı değilse tanımlayalım (Windows vs uyumluluğu)
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#include "Ui.hpp"
int main(int argc, char **argv) {
    Ui().init_ui(argc, argv);
        
}
