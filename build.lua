-- Use löve-build to build the game (https://github.com/ellraiser/love-build)
return {
    name = 'OkaneRun-Classic',
    developer = 'foxplort',
    version = '1.2.0',
    love = '11.5',
    ignore = {'.gitignore', '.git'},
    icon = 'okanerun/assets/images/system/fm.png',

    identifier = "com.foxplort.okanerunclassic",

    use32bit = false,
    platforms = {'windows', 'macos', 'linux'}
}
