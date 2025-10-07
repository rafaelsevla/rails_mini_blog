class Api::PostsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  before_action :set_post, only: [:show, :update, :destroy]
  before_action :authorize_author!, only: [:update, :destroy]

  def index
    @posts = Post.includes(:user).order(created_at: :desc)
    
    render json: {
      posts: @posts.map { |post| post_response(post) }
    }, status: :ok
  end

  def show
    render json: {
      post: post_response(@post)
    }, status: :ok
  end

  def my_posts
    @posts = current_user.posts.order(created_at: :desc)
    
    render json: {
      posts: @posts.map { |post| post_response(post) }
    }, status: :ok
  end

  def posts_by_username
    user = User.find_by(username: params[:username])

    if user.nil?
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    @posts = user.posts.order(created_at: :desc)

    render json: {
      posts: @posts.map { |post| post_response(post) }
    }, status: :ok
  end

  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      render json: {
        message: 'Post created successfully',
        post: post_response(@post)
      }, status: :created
    else
      render json: {
        errors: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render json: {
        message: 'Post updated successfully',
        post: post_response(@post)
      }, status: :ok
    else
      render json: {
        errors: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    
    render json: {
      message: 'Post deleted successfully'
    }, status: :ok
  end

  private

  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: 'Post not found'
    }, status: :not_found
  end

  def authorize_author!
    unless @post.user_id == current_user.id
      render json: {
        error: 'You are not authorized to perform this action'
      }, status: :forbidden
    end
  end

  def post_params
    params.permit(:title, :content)
  end

  def post_response(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      author: {
        username: post.user.username
      },
      created_at: post.created_at,
      updated_at: post.updated_at
    }
  end
end