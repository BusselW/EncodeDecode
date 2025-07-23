const baseUrl = 'https://som.org.om.local/sites/MulderT';

async function getRequestDigest() {
    const response = await fetch(`${baseUrl}/_api/contextinfo`, {
        method: 'POST',
        headers: {
            'Accept': 'application/json;odata=verbose',
            'Content-Type': 'application/json;odata=verbose'
        },
        credentials: 'same-origin'
    });
    
    if (!response.ok) throw new Error('Failed to get request digest');
    
    const data = await response.json();
    return data.d.GetContextWebInformation.FormDigestValue;
}

async function executeSearch(queryText, additionalParams = {}) {
    const defaultParams = {
        querytext: `'${queryText}'`,
        selectproperties: "'Title,Path,HitHighlightedSummary,Summary,Filename,SiteName,ListId,UniqueId'",
        rowlimit: 50,
        startrow: 0,
        enablefql: false,
        enablenicknames: false,
        enablephonetic: false,
        enablestemming: true,
        trimduplicates: true
    };
    
    const params = { ...defaultParams, ...additionalParams };
    const queryString = Object.keys(params)
        .map(key => `${key}=${encodeURIComponent(params[key])}`)
        .join('&');
    
    const response = await fetch(`${baseUrl}/_api/search/query?${queryString}`, {
        method: 'GET',
        headers: {
            'Accept': 'application/json;odata=verbose',
            'Content-Type': 'application/json;odata=verbose'
        },
        credentials: 'same-origin'
    });
    
    if (!response.ok) throw new Error(`Search failed: ${response.status}`);
    
    const data = await response.json();
    return data.d.query.PrimaryQueryResult.RelevantResults.Table.Rows.results || [];
}

async function validateUser() {
    try {
        const response = await fetch(`${baseUrl}/_api/web/currentuser`, {
            headers: {
                'Accept': 'application/json;odata=verbose'
            },
            credentials: 'same-origin'
        });
        
        if (!response.ok) throw new Error('User validation failed');
        
        const data = await response.json();
        return data.d;
    } catch (error) {
        throw new Error('Access denied');
    }
}

async function searchAll(query, includeSubsites = true) {
    const pathFilter = includeSubsites 
        ? `path:"${baseUrl}"` 
        : `site:"${baseUrl}"`;
        
    const fullQuery = `${query} AND ${pathFilter}`;
    
    return await executeSearch(fullQuery);
}

async function searchDocuments(query, includeSubsites = true) {
    const pathFilter = includeSubsites 
        ? `path:"${baseUrl}"` 
        : `site:"${baseUrl}"`;
        
    const docFilter = '(filetype:doc OR filetype:docx OR filetype:pdf OR filetype:ppt OR filetype:pptx OR filetype:xls OR filetype:xlsx OR filetype:aspx)';
    const fullQuery = `${query} AND ${pathFilter} AND ${docFilter}`;
    
    return await executeSearch(fullQuery);
}

async function searchWeekmail(query) {
    const pathFilter = `path:"${baseUrl}/onderdelen/beoordelen"`;
    const filetypeFilter = 'filetype:aspx';
    const weekmailFilter = 'Weekmail';
    
    const fullQuery = `${query} AND ${pathFilter} AND ${filetypeFilter} AND ${weekmailFilter}`;
    
    return await executeSearch(fullQuery);
}

export const searchService = {
    validateUser,
    searchAll,
    searchDocuments,
    searchWeekmail,
    getRequestDigest
};