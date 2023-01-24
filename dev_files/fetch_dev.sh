gh repo clone limanmys/core
gh repo clone limanmys/system-helper
gh repo clone limanmys/php-sandbox
gh repo clone limanmys/webssh
gh repo clone limanmys/fiber-render-engine
cd core/
git submodule init 
git submodule update --recursive
composer install --ignore-platform-reqs