module Capistrano
  module Jira
    class IssueTransiter
      attr_reader :issue

      def initialize(issue)
        @issue = issue
      end

      def transit
        validate_transition
        execute
      end

      private

      def transition
        @transition ||= issue.transitions.all.find do |t|
          t.attrs['name'].casecmp(fetch(:jira_transition_name)).zero?
        end
      end

      def validate_transition
        return if transition
        raise TransitionError,
              "Transition #{fetch(:jira_transition_name)} not available"
      end

      def execute
        issue.transitions.build.save!(transition_hash)
        issue.comments.build.save!(:body => "Deployed to #{fetch(:stage)} in version #{fetch(:version)}")
      rescue JIRA::HTTPError => e
        raise TransitionError, error_message(e)
      end

      def transition_hash
        hash = { transition: { id: transition.id } }
        hash
      end

      def comment_hash
        { update:
          { comment: [
            { add:
               {
                 body: 'Issue transited automatically during deployment.'
               } }
          ] } }
      end
    end
  end
end
