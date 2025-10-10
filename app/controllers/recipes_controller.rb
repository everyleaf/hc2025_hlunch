class RecipesController < ApplicationController
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy ]
  before_action :set_prompt, only: [ :new, :create ]

  def new
    @recipe = @prompt.recipes.build
  end

  def create
    @recipe = @prompt.recipes.build(recipe_params)

    if @recipe.save
      redirect_to @recipe, notice: "レシピを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: "レシピを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to prompt_url(@recipe.prompt), notice: "レシピを削除しました。"
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def set_prompt
    @prompt = Prompt.find(params[:prompt_id])
  end

  def recipe_params
    params.require(:recipe).permit(:title, :ingredients, :instructions)
  end
end
