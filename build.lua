-- Use löve-build to build the game (https://github.com/ellraiser/love-build)
return {
    name = 'OkaneRun',
    developer = 'foxplort',
    version = '0.1.0-dev.1',
    love = '11.5',
    ignore = {'.gitignore', '.git', 'README.md', 'CONTRIBUTING.md'},
    icon = 'assets/images/system/icon-mega.png',

    use32bit = true,
    platforms = {'windows', 'linux'}
}
