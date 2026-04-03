{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$directory$git_branch$gcloud$line_break$character";
      directory = {
        truncation_length = 3;
        fish_style_pwd_dir_length = 1;
        truncation_symbol = "";
        truncate_to_repo = false;
      };
      gcloud = {
        format = "[$symbol$account(@$domain)]($style) ";
      };
    };
  };
}
