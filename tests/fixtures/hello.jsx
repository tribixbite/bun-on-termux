// JSX execution test — verifies JSX transpilation without React
/** @jsxRuntime classic */
/** @jsx h */
function h(tag, props, ...children) {
    return { tag, props, children };
}
const el = <span class="test">hello-jsx</span>;
console.log("hello-jsx:" + (el.tag === "span" ? "ok" : "fail"));
