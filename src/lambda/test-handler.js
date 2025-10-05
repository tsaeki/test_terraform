exports.handler = async (event) => {
    console.log('Test endpoint invoked', JSON.stringify(event));
    
    const response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            message: 'Hello from Lambda!',
            timestamp: new Date().toISOString(),
            status: 'success'
        })
    };
    
    return response;
};
