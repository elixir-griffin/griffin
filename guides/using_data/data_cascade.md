# Data Cascade

Each template is rendered with data that affects the output of the page. This data that is passed into each template is merged from multiple different sources before the template is rendered. The data is merged in a process we call the Data Cascade.

### Sources of Data
When the data is merged as part of the Data Cascade process, the order of priority for sources of data is (from highest priority to lowest):

1. Front Matter Data in a Template
1. Template Data Files *[work in progress]*
1. Directory Data Files (and ascending Parent Directories) *[work in progress]*
1. Front Matter Data in Layouts
1. Configuration Global Data *[work in progress]*
1. Global Data Files
