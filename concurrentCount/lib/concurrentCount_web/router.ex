defmodule ConcurrentCountWeb.Router do
  use ConcurrentCountWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ConcurrentCountWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/pubsub", ConcurrentCountWeb do
    pipe_through :api
    post "/", PageController, :putHandler
    get "/clear", PageController, :clearPutCache
  end

  # Other scopes may use custom stacks.
  # scope "/api", ConcurrentCountWeb do
  #   pipe_through :api
  # end
end
