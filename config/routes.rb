Rails.application.routes.draw do
  post 'data/:id' => 'data#create'
  get 'data/:id' => 'data#show'
  delete 'data/:id' => 'data#destroy'
end
