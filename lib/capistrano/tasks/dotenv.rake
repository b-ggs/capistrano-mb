mb_recipe :dotenv do
  during "provision", "update"
  during "deploy:updating", "update"
end

namespace :mb do
  namespace :dotenv do
    desc "Replace/create .env file with values provided at console"
    task :replace do
      set_up_prompts

      on release_roles(:all) do
        update_dotenv_file
      end
    end

    desc "Update .env file with any missing values"
    task :update do
      set_up_prompts

      on release_roles(:all), :in => :sequence do
        existing_env = if test("[ -f #{shared_dotenv_path} ]")
          download!(shared_dotenv_path)
        end
        update_dotenv_file(existing_env.is_a?(String) ? existing_env : "")
      end
    end

    def shared_dotenv_path
      "#{shared_path}/#{fetch(:mb_dotenv_filename)}"
    end

    def set_up_prompts
      fetch(:mb_dotenv_keys).each do |key|
        if key.to_s =~ /key|token|secret|password|pepper/i
          ask(key, nil, :echo => false)
        else
          ask(key, nil)
        end
      end
    end

    def update_dotenv_file(existing="")
      updated = existing.dup

      fetch(:mb_dotenv_keys).each do |key|
        next if existing =~ /^#{Regexp.escape(key.upcase)}=/
        updated << "\n" unless updated.end_with?("\n")
        updated << "#{key.upcase}=#{fetch(key)}\n"
      end

      unless existing == updated
        put(updated, shared_dotenv_path, :mode => "600")
      end
    end
  end
end
