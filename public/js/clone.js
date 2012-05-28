function clone(user, repo, name) {
    var path_to_repo = '/' + user + '/' + repo;
    $.get(path_to_repo + '/clone.apicmd').success(function(data) {
        var result = data['result'];
        if (result == 'ok') {
            location.reload();
        } else {
            alert(result);
        }
    });
}
