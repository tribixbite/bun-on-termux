// TSX execution test — verifies TypeScript + JSX transpilation without React
// Uses a custom jsxFactory to avoid needing react installed
/** @jsxRuntime classic */
/** @jsx h */
function h(tag: string, props: any, ...children: any[]) {
    return { tag, props, children };
}
const el = <div id="test">hello-tsx</div>;
console.log("hello-tsx:" + (el.tag === "div" ? "ok" : "fail"));
