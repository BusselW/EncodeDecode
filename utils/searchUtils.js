function extractCellValue(cells, propertyName) {
    const cell = cells.find(c => c.Key === propertyName);
    return cell ? cell.Value : '';
}

function processSearchResults(rawResults) {
    return rawResults.map(row => {
        const cells = row.Cells.results;
        return {
            Title: extractCellValue(cells, 'Title'),
            Path: extractCellValue(cells, 'Path'),
            HitHighlightedSummary: extractCellValue(cells, 'HitHighlightedSummary'),
            Summary: extractCellValue(cells, 'Summary'),
            Filename: extractCellValue(cells, 'Filename'),
            SiteName: extractCellValue(cells, 'SiteName'),
            ListId: extractCellValue(cells, 'ListId'),
            UniqueId: extractCellValue(cells, 'UniqueId')
        };
    });
}

function calculateRelevanceScore(result, searchQuery) {
    const query = searchQuery.toLowerCase();
    const title = (result.Title || '').toLowerCase();
    const filename = (result.Filename || '').toLowerCase();
    const summary = (result.Summary || '').toLowerCase();
    
    let score = 0;
    let exactMatch = false;
    
    if (title === query || filename === query) {
        score += 100;
        exactMatch = true;
    } else if (title.includes(query) || filename.includes(query)) {
        score += 50;
        if (title.startsWith(query) || filename.startsWith(query)) {
            score += 25;
        }
    }
    
    if (summary.includes(query)) {
        score += 10;
    }
    
    const queryWords = query.split(' ').filter(word => word.length > 2);
    queryWords.forEach(word => {
        if (title.includes(word)) score += 5;
        if (filename.includes(word)) score += 5;
        if (summary.includes(word)) score += 2;
    });
    
    return { score, exactMatch };
}

function sortByRelevance(rawResults, searchQuery) {
    const processedResults = processSearchResults(rawResults);
    
    const resultsWithScores = processedResults.map(result => {
        const { score, exactMatch } = calculateRelevanceScore(result, searchQuery);
        return {
            ...result,
            relevanceScore: score,
            exactMatch
        };
    });
    
    return resultsWithScores.sort((a, b) => {
        if (a.exactMatch && !b.exactMatch) return -1;
        if (!a.exactMatch && b.exactMatch) return 1;
        return b.relevanceScore - a.relevanceScore;
    });
}

function highlightSearchTerms(text, searchQuery) {
    if (!text || !searchQuery) return text;
    
    const words = searchQuery.toLowerCase().split(' ').filter(word => word.length > 1);
    let highlightedText = text;
    
    words.forEach(word => {
        const regex = new RegExp(`(${word})`, 'gi');
        highlightedText = highlightedText.replace(regex, '<mark>$1</mark>');
    });
    
    return highlightedText;
}

function formatSearchResults(results, searchQuery) {
    return results.map(result => ({
        ...result,
        highlightedTitle: highlightSearchTerms(result.Title, searchQuery),
        highlightedSummary: highlightSearchTerms(result.Summary, searchQuery)
    }));
}

export const utilUtils = {
    processSearchResults,
    sortByRelevance,
    highlightSearchTerms,
    formatSearchResults,
    calculateRelevanceScore
};