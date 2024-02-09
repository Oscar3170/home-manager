{ home, config, pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubeswitch
    krew

    kops

    aws-iam-authenticator
  ];

  programs.k9s = {
    enable = true;
  };

  # programs.fish.plugins = [
  #   {
  #     name = "kubectl-completions";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "evanlucas";
  #       repo = "fish-kubectl-completions";
  #       rev = "ced676392575d618d8b80b3895cdc3159be3f628";
  #       sha256 = "sha256-OYiYTW+g71vD9NWOcX1i2/TaQfAg+c2dJZ5ohwWSDCc=";
  #     };
  #   }
  # ];

  home.file.".local/bin/kubernetes/".source = ./bin;
  home.sessionPath = [
    "$HOME/.local/bin/kubernetes"
  ];

  home.shellAliases = {
    k = "kubectl";
    kd = "kubectl describe";

    kgs = "kubectl get svc";

    kgp = "kubectl watch";
    kdp = "kubectl describe pod";
    kaf = "kubectl apply -f";
  };

}
