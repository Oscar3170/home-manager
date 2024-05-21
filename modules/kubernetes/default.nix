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

  home.file.".local/bin/kubernetes/".source = ./bin;
  home.sessionPath = [
    "$HOME/.local/bin/kubernetes"
  ];

  home.shellAliases = {
    k = "kubectl";
    kd = "kubectl describe";
    kl = "kubectl log";

    kgs = "kubectl get svc";

    kgp = "kubectl watch";
    kdp = "kubectl describe pod";
    kaf = "kubectl apply -f";
  };

}
