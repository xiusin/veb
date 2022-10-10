module veb

pub struct Trier {
mut:
	root &Node
	size int
}

const nul = ""

pub fn new_trie() &Trier {
	return &Trier{
		root: &Node{
			depth: 0
			children: map[string]&Node{}
			parent: unsafe { nil }
			re: unsafe { nil }
		}
		size: 0
	}
}

pub fn (mut t Trier) root() &Node {
	return t.root
}

pub fn (mut t Trier) add(key string, handler VebHandler, mws []VebHandler) &Node {
	unsafe {
		t.size++
		segments := key.split("/")
		mut node := t.root	// 根节点
		node.term_count ++

		for _, segment in segments {
			if segment in node.children {
				node = node.children[segment]
			} else {
				chr := segment[0..1].str()
				is_pattern := match chr {
					'*', ':' { true }
					else { false }
				}
				mut param_name := ""
				if is_pattern {
					if chr == ':' {
						param_name = segment[1..]
						segment = '(?P<${param_name}>.+)'
					} else if chr == '*'{
						if segment.len > 1 {
							param_name = segment[1..]
							segment = "(?P<${param_name}>.*)"
						} else {
							segment = "(.*)"
						}
					}
				}

				node = node.new_child(segment, "", nil, false, false)
				node.set_pattern(is_pattern, segment, param_name)
			}

			node.term_count++
		}

		return node.new_child(nul, key, handler, true, false)
	}
}

pub fn (mut t Trier) find(key string) (&Node , map[string]string, bool) {
	unsafe {
		mut params := map[string]string{}

		node := find_node(t.root(), key.split("/"), mut &params)
		if node == nil {
			return nil, map[string]string{}, false
		}
		children := node.children()
		if nul !in children { // 还没有初始化过
			return nil, map[string]string{}, false
		}
		child := children[nul]
		if !child.term {
			return nil, map[string]string{}, false
		}
		return child, params, true
	}
}

// 查找树节点
fn find_node(node &Node, segments []string, mut params &map[string]string) &Node {
	unsafe {
		if node == nil {
			return nil
		}
	}
	if segments.len == 0 {
		unsafe {
			return node
		}
	}

	mut children := node.children()

	mut n :=  &Node{ parent: unsafe { nil }, re: unsafe { nil }}

	if segments[0] !in children {
		mut flag := false
		for m, _ in children {
			if !children[m].is_pattern {
				continue
			}

			res := children[m].re.find_all_str(segments[0])
			if res.len > 0 {
				flag = true
				params[children[m].param_name] = res[0]
				unsafe { n = children[m] }
				break
			}
		}
		if !flag {
			return unsafe { nil }
		}
	} else {
		n = children[segments[0]]
	}

	mut nsegments := []string{}

	if segments.len > 1 {
		nsegments = segments[1..]
	}
	return find_node(n, nsegments, mut params)
}
