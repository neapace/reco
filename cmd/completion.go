package cmd

import (
	"github.com/ReconfigureIO/cobra"
	"github.com/ReconfigureIO/reco/logger"
)

// completionCmd represents the completion command
var completionCmd = &cobra.Command{
	Use:   "completion [file]",
	Short: "Generate a bash completion script",
	Run:   completion,
}

func init() {
	RootCmd.AddCommand(completionCmd)
}

func completion(cmd *cobra.Command, args []string) {
	fileName := "reco-completion.sh"
	if len(args) > 0 {
		fileName = args[0]
	}
	if err := cmd.Root().GenBashCompletionFile(fileName); err != nil {
		exitWithError(err)
	}
	logger.Std.Printf("generated %s", fileName)
}
