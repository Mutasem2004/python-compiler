lexer grammar PythonLexer;

tokens { INDENT, DEDENT }

@header {
    import org.antlr.v4.runtime.CommonToken;
    import java.util.Stack;
    import java.util.LinkedList;
    import java.util.Queue;
}

@members {
    Stack<Integer> indentStack = new Stack<>();
    Queue<Token> tokenQueue = new LinkedList<>();
    boolean atStartOfLine = true;
    int opened = 0;

    { indentStack.push(0); }

    @Override
    public Token nextToken() {
        if (!tokenQueue.isEmpty()) return tokenQueue.poll();

        Token next = super.nextToken();
        int type = next.getType();


        if (type == LBRACK || type == LSBRACK || type == LCBRACK) {
            opened++;
        } else if (type == RBRACK || type == RSBRACK || type == RCBRACK) {
            opened--;
        }


        if (opened > 0 && (type == NEWLINE || type == WS)) {
            return nextToken();
        }


        if (atStartOfLine) {
            if (type == NEWLINE) {

                return next;
            }

            atStartOfLine = false;

            int indent = 0;
            Token contentToken = next;

            if (type == WS) {
                String ws = next.getText();
                for (char c : ws.toCharArray()) indent += (c == '\t' ? 4 : 1);
                contentToken = super.nextToken();
                if (contentToken.getType() == NEWLINE) {
                    atStartOfLine = true;
                    return contentToken;
                }
            } else {
                indent = 0;
            }

            int previousIndent = indentStack.peek();


            if (indent > previousIndent) {
                indentStack.push(indent);
                tokenQueue.add(createToken(INDENT, contentToken));
            }

            else if (indent < previousIndent) {
                while (indent < indentStack.peek()) {
                    indentStack.pop();
                    tokenQueue.add(createToken(DEDENT, contentToken));
                }
            }

            tokenQueue.add(contentToken);
            return tokenQueue.poll();
        }


        if (type == NEWLINE) {
            atStartOfLine = true;
        }


        if (type == WS) return nextToken();

        return next;
    }

    private CommonToken createToken(int type, Token origin) {
        CommonToken t = new CommonToken(type, type == INDENT ? "INDENT" : "DEDENT");
        t.setLine(origin.getLine());
        t.setCharPositionInLine(origin.getCharPositionInLine());
        return t;
    }
}