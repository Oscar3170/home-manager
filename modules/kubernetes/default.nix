{ home, config, pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubeswitch
    krew

    kops

    kubernetes-helm
    helm-ls

    aws-iam-authenticator
  ];

  programs.k9s = {
    enable = true;
  };

  home.file.".local/bin/kubernetes/".source = ./bin;
  home.sessionPath = [
    "$HOME/.local/bin/kubernetes"
  ];

  programs.fish.shellAbbrs = {
    k = "kubectl";
    kd = "kubectl describe";
    kl = "kubectl log";

    kgs = "kubectl get svc";

    kgp = "kubectl cget";
    kdp = "kubectl describe pod";
    kaf = "kubectl apply -f";
  };
}
