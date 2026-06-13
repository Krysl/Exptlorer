use proc_macro::TokenStream;
use quote::quote;
use std::fs;
use std::path::{Path, PathBuf};

struct DocPath {
    krate: String,
    ty: String,
    method: Option<String>,
}

impl DocPath {
    /// 解析路径：
    ///   `"sysinfo::Disk.kind"`   → krate=sysinfo, ty=Disk, method=kind
    ///   `"sysinfo::DiskKind"`    → krate=sysinfo, ty=DiskKind, method=None（类型本身的文档）
    fn parse(input: &str) -> Result<Self, &'static str> {
        // 按 `.` 分割，最后一段是 method（如果有）
        let (rest, method) = match input.rsplit_once('.') {
            Some((r, m)) => (r, Some(m)),
            None => (input, None),
        };
        let parts: Vec<&str> = rest.split("::").collect();
        if parts.len() < 2 {
            return Err("doc_from path must be \"crate::Type\" or \"crate::Type.method\"");
        }
        Ok(Self {
            krate: parts[0].to_string(),
            ty: parts[parts.len() - 1].to_string(),
            method: method.map(String::from),
        })
    }
}

fn cargo_home() -> Option<PathBuf> {
    if let Ok(val) = std::env::var("CARGO_HOME") {
        return Some(PathBuf::from(val));
    }
    // Windows 默认 %USERPROFILE%\.cargo
    if let Ok(profile) = std::env::var("USERPROFILE") {
        return Some(PathBuf::from(format!("{}/.cargo", profile)));
    }
    // Unix 默认 ~/.cargo
    if let Ok(home) = std::env::var("HOME") {
        return Some(PathBuf::from(format!("{home}/.cargo")));
    }
    None
}

fn find_crate_src_dir(krate: &str) -> Option<PathBuf> {
    let registry_src = cargo_home()?.join("registry").join("src");
    if !registry_src.exists() {
        return None;
    }
    for entry in fs::read_dir(&registry_src).ok()? {
        let hash_dir = entry.ok()?.path();
        if !hash_dir.is_dir() {
            continue;
        }
        for sub in fs::read_dir(&hash_dir).ok()? {
            let sub = sub.ok()?;
            let name = sub.file_name().to_string_lossy().to_string();
            let path = sub.path();
            if path.is_dir() && name.starts_with(&format!("{krate}-")) {
                return Some(path.join("src"));
            }
        }
    }
    None
}

fn find_target_doc_attrs(src_dir: &Path, ty: &str, method: Option<&str>) -> Option<Vec<syn::Attribute>> {
    let mut docs = Vec::new();
    scan_dir(src_dir, &mut docs, ty, method);
    docs.into_iter().next()
}

fn scan_dir(dir: &Path, results: &mut Vec<Vec<syn::Attribute>>, ty: &str, method: Option<&str>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            scan_dir(&path, results, ty, method);
        } else if path.extension().map_or(false, |e| e == "rs") {
            if let Ok(code) = fs::read_to_string(&path) {
                if let Some(doc) = extract_doc(&code, ty, method) {
                    results.push(doc);
                }
            }
        }
    }
}

fn extract_doc(source: &str, ty: &str, method: Option<&str>) -> Option<Vec<syn::Attribute>> {
    let syntax: syn::File = syn::parse_file(source).ok()?;

    if let Some(method_name) = method {
        // 在 impl Type { fn method ... } 中查找
        for item in &syntax.items {
            let imp = match item {
                syn::Item::Impl(i) => i,
                _ => continue,
            };
            let type_ident = match &*imp.self_ty {
                syn::Type::Path(p) => p.path.segments.last().map(|s| s.ident.to_string()),
                _ => None,
            };
            if type_ident.as_deref() != Some(ty) {
                continue;
            }
            for impl_item in &imp.items {
                let fn_item = match impl_item {
                    syn::ImplItem::Fn(f) => f,
                    _ => continue,
                };
                if fn_item.sig.ident != method_name {
                    continue;
                }
                let doc = collect_doc(&fn_item.attrs);
                if !doc.is_empty() {
                    return Some(doc);
                }
            }
        }
    } else {
        // 在顶层查找 enum / struct Type
        for item in &syntax.items {
            let ident = match item {
                syn::Item::Enum(e) => &e.ident,
                syn::Item::Struct(s) => &s.ident,
                _ => continue,
            };
            if ident != ty {
                continue;
            }
            let doc = collect_doc(match item {
                syn::Item::Enum(e) => &e.attrs,
                syn::Item::Struct(s) => &s.attrs,
                _ => unreachable!(),
            });
            if !doc.is_empty() {
                return Some(doc);
            }
        }
    }
    None
}

fn collect_doc(attrs: &[syn::Attribute]) -> Vec<syn::Attribute> {
    attrs
        .iter()
        .filter(|a| a.path().is_ident("doc"))
        .map(|a| {
            // /// text 在 proc_macro2 词法分析后存为 "/ text"（// 注释 + 剩余内容）
            // 需要去除开头的 "/ " 前缀
            if let syn::Meta::NameValue(meta) = &a.meta {
                if let syn::Expr::Lit(expr_lit) = &meta.value {
                    if let syn::Lit::Str(lit_str) = &expr_lit.lit {
                        let original = lit_str.value();
                        // proc_macro2 把 "/// text" 存为 "/ text"
                        // 只去掉开头的 "/" 以及紧随的一个空格，保留后续缩进
                        let clean = original
                            .strip_prefix('/')
                            .and_then(|s| s.strip_prefix(' '))
                            .or_else(|| original.strip_prefix('/'))
                            .unwrap_or(&original);
                        return syn::Attribute {
                            pound_token: Default::default(),
                            bracket_token: Default::default(),
                            style: syn::AttrStyle::Outer,
                            meta: syn::Meta::NameValue(syn::MetaNameValue {
                                path: syn::parse_quote!(doc),
                                eq_token: Default::default(),
                                value: syn::Expr::Lit(syn::ExprLit {
                                    attrs: vec![],
                                    lit: syn::Lit::Str(syn::LitStr::new(
                                        clean,
                                        proc_macro2::Span::call_site(),
                                    )),
                                }),
                            }),
                        };
                    }
                }
            }
            a.clone()
        })
        .collect()
}

#[proc_macro_attribute]
pub fn doc_from(attr: TokenStream, item: TokenStream) -> TokenStream {
    let attr_str = attr.to_string();
    let path_str = attr_str.trim().trim_matches('"');

    let doc_path = match DocPath::parse(path_str) {
        Ok(p) => p,
        Err(e) => {
            return syn::Error::new_spanned(
                &syn::parse::<syn::Item>(item.clone()).unwrap(),
                e,
            )
            .to_compile_error()
            .into();
        }
    };

    let src_dir = match find_crate_src_dir(&doc_path.krate) {
        Some(d) => d,
        None => {
            let searched = cargo_home()
                .map(|p| p.join("registry").join("src"))
                .unwrap_or_default();
            let msg = format!(
                "doc_from: cannot find crate `{}` source in {:?}",
                doc_path.krate, searched,
            );
            return syn::Error::new_spanned(
                &syn::parse::<syn::Item>(item.clone()).unwrap(),
                msg,
            )
            .to_compile_error()
            .into();
        }
    };

    let doc_attrs = match find_target_doc_attrs(&src_dir, &doc_path.ty, doc_path.method.as_deref()) {
        Some(d) => d,
        None => {
            let target_desc = match &doc_path.method {
                Some(m) => format!("{}::{}", doc_path.ty, m),
                None => doc_path.ty.clone(),
            };
            let msg = format!(
                "doc_from: cannot find doc for `{}::{}` in {:?}",
                doc_path.krate, target_desc, src_dir
            );
            return syn::Error::new_spanned(
                &syn::parse::<syn::Item>(item.clone()).unwrap(),
                msg,
            )
            .to_compile_error()
            .into();
        }
    };

    let mut item = syn::parse::<syn::Item>(item).expect("doc_from can only be applied to items");

    // 把原目标的 #[doc] 属性插入到当前 item 属性最前面
    let attrs = match &mut item {
        syn::Item::Fn(f) => &mut f.attrs,
        syn::Item::Enum(e) => &mut e.attrs,
        syn::Item::Struct(s) => &mut s.attrs,
        syn::Item::Trait(t) => &mut t.attrs,
        syn::Item::Type(t) => &mut t.attrs,
        syn::Item::Impl(i) => &mut i.attrs,
        syn::Item::Const(c) => &mut c.attrs,
        syn::Item::Static(s) => &mut s.attrs,
        syn::Item::Mod(m) => &mut m.attrs,
        syn::Item::Use(u) => &mut u.attrs,
        syn::Item::ForeignMod(f) => &mut f.attrs,
        syn::Item::Macro(m) => &mut m.attrs,
        _ => {
            return syn::Error::new_spanned(
                &item,
                "doc_from: unsupported item type",
            )
            .to_compile_error()
            .into();
        }
    };

    for (i, attr) in doc_attrs.iter().enumerate() {
        attrs.insert(i, attr.clone());
    }

    quote!(#item).into()
}
