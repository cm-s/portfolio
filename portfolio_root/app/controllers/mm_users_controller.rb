class MmUsersController < ApplicationController
  # apply ApplicationController actions to logged users
  before_action :authenticate_login, :only => [:desktop, :setting]
  before_action :enforce_logged_state, :only => [:new, :create, :login]

  def show
    title = "Material Messenger"
    @page = "messenger"
    @users = User.all.order('created_at ASC') # ordering users from least current to most
  end
  def search
    matches = scanDB(params[:query])
    respond_to do |response|
      data = { :status => 'ok', :data => matches }
      response.json { render :json => data }
    end
  end

  # The view (new) and the action of creating the user (create)
  def new
    @page = "new messenger"
    @user = User.new
  end
  def create
    @users = User.all.order('created_at ASC')
    @user = User.new(user_params)
    if @user.save! && 1#secureParams(@user.user_name)
      puts "MessengerController: Database entry creation successful"
      session[:logged_user_id] = @user.id
      flash[:postprocess] = "User Created Successfully"
      @page = "messenger"
      redirect_to("/mm_users/#{session[:logged_user_id]}")
    else
      puts "MessengerController: Database entry creation unsuccessful"
      flash[:user_error] = "...Something Went Wrong"
      render(:new)
    end
  end

  # The view (logon) and the action of logging in (login)
  # As well as the action of logging out (logout)
  def logon
    @page = "login messenger"
    render(:login)
  end
  def login
    logged_user = User.authenticate(params[:user_name], params[:password])

    if logged_user # If authentication returns, being anything other than false (an object)
      session[:logged_user_id] = logged_user.id
      puts "MessengerController: Success; User logged in sucessfully"
      flash[:postprocess] = "Logged In Successfully"
      @page = "messenger"
      @users = User.all.order('created_at ASC')
      redirect_to("/mm_users/#{session[:logged_user_id]}")
    else
      puts "MessengerController: Failure; Invalid Credentials, User redirected"
      flash[:user_error] = "Couldn\'t Log In"
      render(:login)
    end
  end
  def logout
    reset_session
    puts "MessengerController: Logout Succeded. Redirecting to root"
    flash[:postprocess] = "Logout Succeded"
    redirect_to(root_url)
  end

  # Member functions private for heightened security
  private

  def secureParams(input)
    puts input
    filtered = input.scan(/\{|\}|\(|\)|\&|\$|#|\[|\]|\*|\^|\:|\;/i)
    if filtered.length
      false
    end
    true
  end

  def scanDB(query)
    results = []
    User.all.each do |usr|
      if usr.first_name.scan(/#{query}/i).length > 0
        sanitized = usr.attributes
        sanitized.compact!
        sanitized.except!('user_name', 'password', 'created_at')
        results.push(sanitized)
      end
    end
    results.to_json
  end

  def user_params
    params.require(:messenger).permit(:user_name, :password, :first_name, :last_name, :image)
  end
end
