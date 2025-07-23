<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Search Center - MulderT</title>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <link rel="stylesheet" href="./css/search_style.css">
</head>
<body>
    <div id="search-app"></div>
    
    <script type="module">
        import { searchService } from './services/searchService.js';
        import { utilUtils } from './utils/searchUtils.js';
        import SearchInterface from './ui/SearchInterface.js';
        
        const { createElement: h, useState, useEffect } = React;
        
        function ValidationLayer() {
            const [userValid, setUserValid] = useState(false);
            const [loading, setLoading] = useState(true);
            
            useEffect(() => {
                searchService.validateUser()
                    .then(() => setUserValid(true))
                    .catch(() => setUserValid(false))
                    .finally(() => setLoading(false));
            }, []);
            
            if (loading) return h('div', {className: 'loading'}, 'Checking permissions...');
            if (!userValid) return h('div', {className: 'error'}, 'Access denied. Please contact administrator.');
            
            return h(MainApp);
        }
        
        function MainApp() {
            const [searchQuery, setSearchQuery] = useState('');
            const [searchType, setSearchType] = useState('all');
            const [results, setResults] = useState([]);
            const [loading, setLoading] = useState(false);
            const [filters, setFilters] = useState({
                subsites: true,
                documents: false,
                weekmail: false
            });
            
            const handleSearch = async () => {
                if (!searchQuery.trim()) return;
                
                setLoading(true);
                try {
                    let searchResults;
                    
                    if (filters.weekmail) {
                        searchResults = await searchService.searchWeekmail(searchQuery);
                    } else if (filters.documents) {
                        searchResults = await searchService.searchDocuments(searchQuery, filters.subsites);
                    } else {
                        searchResults = await searchService.searchAll(searchQuery, filters.subsites);
                    }
                    
                    const sortedResults = utilUtils.sortByRelevance(searchResults, searchQuery);
                    setResults(sortedResults);
                } catch (error) {
                    console.error('Search failed:', error);
                    setResults([]);
                } finally {
                    setLoading(false);
                }
            };
            
            const handleFilterChange = (filterName, value) => {
                setFilters(prev => ({
                    ...prev,
                    [filterName]: value
                }));
            };
            
            return h('div', {className: 'search-container'},
                h('header', {className: 'search-header'},
                    h('h1', null, 'SharePoint Search Center'),
                    h('p', null, 'Search across MulderT sites and documents')
                ),
                
                h(SearchInterface, {
                    searchQuery,
                    setSearchQuery,
                    filters,
                    onFilterChange: handleFilterChange,
                    onSearch: handleSearch,
                    loading
                }),
                
                h(SearchResults, {
                    results,
                    loading,
                    query: searchQuery
                })
            );
        }
        
        function SearchResults({ results, loading, query }) {
            if (loading) {
                return h('div', {className: 'loading'}, 'Searching...');
            }
            
            if (!results.length) {
                return query ? h('div', {className: 'no-results'}, 'No results found') : null;
            }
            
            return h('div', {className: 'results-container'},
                h('div', {className: 'results-header'},
                    `Found ${results.length} result(s) for "${query}"`
                ),
                h('div', {className: 'results-list'},
                    results.map((result, index) =>
                        h('div', {
                            key: index,
                            className: `result-item ${result.exactMatch ? 'exact-match' : 'fuzzy-match'}`
                        },
                            h('h3', {className: 'result-title'},
                                h('a', {
                                    href: result.Path,
                                    target: '_blank'
                                }, result.Title || result.Filename)
                            ),
                            h('div', {className: 'result-path'}, result.Path),
                            h('div', {className: 'result-summary'}, result.HitHighlightedSummary || result.Summary),
                            result.exactMatch && h('span', {className: 'exact-badge'}, 'Exact Match')
                        )
                    )
                )
            );
        }
        
        function AppWrapper() {
            return h(ValidationLayer);
        }
        
        const root = ReactDOM.createRoot(document.getElementById('search-app'));
        root.render(h(AppWrapper));
    </script>
</body>
</html>