const { createElement: h } = React;

function SearchInterface({ 
    searchQuery, 
    setSearchQuery, 
    filters, 
    onFilterChange, 
    onSearch, 
    loading 
}) {
    const handleSubmit = (e) => {
        e.preventDefault();
        onSearch();
    };
    
    const handleKeyPress = (e) => {
        if (e.key === 'Enter') {
            onSearch();
        }
    };
    
    const handleFilterToggle = (filterName) => {
        if (filterName === 'weekmail' && !filters.weekmail) {
            onFilterChange('subsites', true);
            onFilterChange('documents', false);
            onFilterChange('weekmail', true);
        } else if (filterName === 'documents' && !filters.documents) {
            onFilterChange('weekmail', false);
            onFilterChange('documents', true);
        } else if (filterName === 'subsites') {
            onFilterChange('subsites', !filters.subsites);
        } else {
            onFilterChange(filterName, false);
        }
    };
    
    return h('div', { className: 'search-interface' },
        h('form', { onSubmit: handleSubmit, className: 'search-form' },
            h('div', { className: 'search-input-container' },
                h('input', {
                    type: 'text',
                    value: searchQuery,
                    onChange: (e) => setSearchQuery(e.target.value),
                    onKeyPress: handleKeyPress,
                    placeholder: 'Enter search terms...',
                    className: 'search-input',
                    disabled: loading
                }),
                h('button', {
                    type: 'submit',
                    className: 'search-button',
                    disabled: loading || !searchQuery.trim()
                }, loading ? 'Searching...' : 'Search')
            )
        ),
        
        h('div', { className: 'search-filters' },
            h('h3', null, 'Search Filters'),
            
            h('div', { className: 'filter-group' },
                h('label', { className: 'filter-label' },
                    h('input', {
                        type: 'checkbox',
                        checked: filters.subsites,
                        onChange: () => handleFilterToggle('subsites'),
                        className: 'filter-checkbox'
                    }),
                    h('span', null, 'Include Sub-sites'),
                    h('small', null, ' (Search across all MulderT sub-sites)')
                )
            ),
            
            h('div', { className: 'filter-group' },
                h('label', { className: 'filter-label' },
                    h('input', {
                        type: 'checkbox',
                        checked: filters.documents,
                        onChange: () => handleFilterToggle('documents'),
                        className: 'filter-checkbox'
                    }),
                    h('span', null, 'Documents Only'),
                    h('small', null, ' (Word, Excel, PowerPoint, PDF, ASPX files)')
                )
            ),
            
            h('div', { className: 'filter-group' },
                h('label', { className: 'filter-label' },
                    h('input', {
                        type: 'checkbox',
                        checked: filters.weekmail,
                        onChange: () => handleFilterToggle('weekmail'),
                        className: 'filter-checkbox'
                    }),
                    h('span', null, 'Weekmail Search'),
                    h('small', null, ' (Search .aspx files in /onderdelen/beoordelen containing "Weekmail")')
                )
            )
        ),
        
        filters.weekmail && h('div', { className: 'weekmail-info' },
            h('p', null, 
                h('strong', null, 'Weekmail Search Active: '),
                'Searching for .aspx files in /sites/muldert/onderdelen/beoordelen and sub-sites containing "Weekmail"'
            )
        )
    );
}

export default SearchInterface;