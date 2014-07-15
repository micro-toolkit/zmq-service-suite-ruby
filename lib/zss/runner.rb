require 'daemons'

module ZSS
  class Runner

    def self.run(proc_name)
      proc_name = proc_name.to_s
      pid_path = log_path = './log'

      FileUtils.mkdir_p pid_path
      FileUtils.mkdir_p log_path

      daemon_opts = {
        multiple:   true,
        dir_mode:   :normal,
        dir:        pid_path,
        log_output: true,
        stop_proc:  lambda do
          puts "stop #{proc_name} daemon..."
          $stop_requested = true
        end
      }

      puts "Starting #{proc_name}:\n\tPID: #{pid_path}\n\tLOGS: #{log_path}"

      Daemons.run_proc proc_name, daemon_opts do
        daemon = ZSS::ServiceRegister.get_service

        puts "Started #{proc_name} daemon..."
        daemon.run

        puts "Stoping #{proc_name} daemon"
        exit 0
      end
    end
  end
end
