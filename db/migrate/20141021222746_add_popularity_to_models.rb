class AddPopularityToModels < ActiveRecord::Migration
  def change
    add_column :quizzes,         :popularity, :float, :default => 0.0
    add_column :statuses,        :popularity, :float, :default => 0.0
    add_column :keyword_updates, :popularity, :float, :default => 0.0
  end
end
