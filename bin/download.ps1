$url = $args[0];

function download([string]$url) {
    $dest = $url.substring($url.lastindexof('/')+1)
    if (!(test-path $dest)) {
        (new-object system.net.webclient).downloadfile($url, $dest);
    }
}

download $url