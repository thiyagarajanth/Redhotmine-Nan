# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match 'tickets/request', :to => 'api_tickets#create', :via => [:get,:post]
match 'tickets/index', :to => 'api_tickets#index', :via => [:get, :post]

match 'tickets/create_update_category', :to => 'api_tickets#create_update_category', :via => [:put, :post]
match 'tickets/create_update_tags', :to => 'api_tickets#create_update_tags', :via => [:put, :post]
match 'tickets/tag_category_statuses', :to => 'api_tickets#tag_category_statuses', :via => [:put, :post]
match 'tickets/create_ticket_with_attachment', :to => 'api_tickets#create_ticket_with_attachment', :via => [:put, :post]
match 'tickets/close_ticket', :to => 'api_tickets#close_ticket', :via => [:put,:post]
match 'tickets/:id', :to => 'api_tickets#close_ticket', :via => [:put]
match 'tickets', :to => 'api_tickets#create', :via => [:post]

match '/mapp/tickets'               => 'mapp/tickets#index', :via => [:get]
match '/mapp/tickets/:id'           => 'mapp/tickets#show', :via => [:get]
match '/mapp/tickets/:id/approve' => 'mapp/tickets#approve', :via => [:put, :post]
match '/mapp/tickets/:id/reject'  => 'mapp/tickets#reject', :via => [:put, :post]
match '/mapp/tickets/:id/clarify' => 'mapp/tickets#clarify', :via => [:put, :post]



