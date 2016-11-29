class DataController < ApplicationController
  def create
    message = Message.find(params[:id])
    message.body = request.raw_post
    message.save
    head :ok
  rescue  Database::MissingKeyError
    Message.new(key: params[:id], body: request.raw_post).save
    head :ok
  end

  def destroy
    Message.find(params[:id]).delete
    head :ok
  rescue  Database::MissingKeyError
    head :not_found
  end

  def show
    message = Message.find(params[:id])
    render plain: message.body
  rescue  Database::MissingKeyError
    head :not_found
  end
end
