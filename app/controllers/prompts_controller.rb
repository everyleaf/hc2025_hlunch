class PromptsController < ApplicationController
  before_action :set_prompt, only: [ :show, :edit, :update, :destroy ]

  def index
    @prompts = Prompt.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @prompt = Prompt.new
  end

  def create
    @prompt = Prompt.new(prompt_params)

    if @prompt.save
      redirect_to @prompt, notice: "プロンプトを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prompt.update(prompt_params)
      redirect_to @prompt, notice: "プロンプトを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prompt.destroy
    redirect_to prompts_url, notice: "プロンプトを削除しました。"
  end

  private

  def set_prompt
    @prompt = Prompt.find(params[:id])
  end

  def prompt_params
    params.require(:prompt).permit(:title, :prompt)
  end
end
