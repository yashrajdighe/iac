function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // 1. If it's a directory-like path without a slash and no file extension
    // Redirect /app to /app/ so the browser resolves relative paths correctly
    if (!uri.includes('.') && !uri.endsWith('/')) {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: uri + '/' }
            }
        };
    }

    // 2. If it ends in /, append index.html for S3 to find the file
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }

    return request;
}
